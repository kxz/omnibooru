class Dmail < ActiveRecord::Base
  validates_presence_of :to_id
  validates_presence_of :from_id
  validates_format_of :title, :with => /\S/
  validates_format_of :body, :with => /\S/
  validate :validate_sender_is_not_banned
  before_validation :initialize_from_id, :on => :create
  belongs_to :owner, :class_name => "User"
  belongs_to :to, :class_name => "User"
  belongs_to :from, :class_name => "User"
  before_create :auto_delete_if_filtered
  after_create :update_recipient
  after_create :send_dmail
  attr_accessible :title, :body, :is_deleted, :to_id, :to, :to_name, :creator_ip_addr

  module AddressMethods
    def to_name
      User.id_to_pretty_name(to_id)
    end

    def from_name
      User.id_to_pretty_name(from_id)
    end

    def to_name=(name)
      user = User.find_by_name(name)
      return if user.nil?
      self.to_id = user.id
    end

    def initialize_from_id
      self.from_id = CurrentUser.id
    end
  end

  module FactoryMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def create_split(params)
        copy = nil

        Dmail.transaction do
          copy = Dmail.new(params)
          copy.owner_id = copy.to_id
          unless copy.to_id == CurrentUser.id
            copy.save
          end

          copy = Dmail.new(params)
          copy.owner_id = CurrentUser.id
          copy.is_read = true
          copy.save
        end

        copy
      end

      def new_blank
        Dmail.new do |dmail|
          dmail.from_id = CurrentUser.id
        end
      end
    end

    def build_response(options = {})
      Dmail.new do |dmail|
        if title =~ /Re:/
          dmail.title = title
        else
          dmail.title = "Re: #{title}"
        end
        dmail.owner_id = from_id
        dmail.body = quoted_body
        dmail.to_id = from_id unless options[:forward]
        dmail.from_id = to_id
      end
    end
  end

  module SearchMethods
    def for(user)
      where("owner_id = ?", user)
    end

    def inbox
      where("to_id = owner_id")
    end

    def sent
      where("from_id = owner_id")
    end

    def active
      where("is_deleted = ?", false)
    end

    def deleted
      where("is_deleted = ?", true)
    end

    def search_message(query)
      if query =~ /\*/ && CurrentUser.user.is_builder?
        escaped_query = query.to_escaped_for_sql_like
        where("(title ILIKE ? ESCAPE E'\\\\' OR body ILIKE ? ESCAPE E'\\\\')", escaped_query, escaped_query)
      else
        where("message_index @@ plainto_tsquery(?)", query.to_escaped_for_tsquery_split)
      end
    end

    def unread
      where("is_read = false and is_deleted = false")
    end

    def visible
      where("owner_id = ?", CurrentUser.id)
    end

    def to_name_matches(name)
      where("to_id = (select _.id from users _ where lower(_.name) = ?)", name.mb_chars.downcase)
    end

    def from_name_matches(name)
      where("from_id = (select _.id from users _ where lower(_.name) = ?)", name.mb_chars.downcase)
    end

    def search(params)
      q = where("true")
      return q if params.blank?

      if params[:message_matches].present?
        q = q.search_message(params[:message_matches])
      end

      if params[:owner_id].present?
        q = q.for(params[:owner_id].to_i)
      end

      if params[:to_name].present?
        q = q.to_name_matches(params[:to_name])
      end

      if params[:to_id].present?
        q = q.where("to_id = ?", params[:to_id].to_i)
      end

      if params[:from_name].present?
        q = q.from_name_matches(params[:from_name])
      end

      if params[:from_id].present?
        q = q.where("from_id = ?", params[:from_id].to_i)
      end

      if params[:read] == "true"
        q = q.where("is_read = true")
      elsif params[:read] == "false"
        q = q.unread
      end

      q
    end
  end

  include AddressMethods
  include FactoryMethods
  extend SearchMethods

  def validate_sender_is_not_banned
    if from.is_banned?
      errors[:base] = "Sender is banned and cannot send messages"
      return false
    else
      return true
    end
  end

  def quoted_body
    "[quote]\n#{from_name} said:\n\n#{body}\n[/quote]\n\n"
  end

  def send_dmail
    if to.receive_email_notifications? && to.email.include?("@") && owner_id == to.id
      UserMailer.dmail_notice(self).deliver
    end
  end

  def mark_as_read!
    update_column(:is_read, true)

    unless Dmail.where(:is_read => false, :owner_id => CurrentUser.user.id).exists?
      CurrentUser.user.update_attribute(:has_mail, false)
    end
  end

  def auto_delete_if_filtered
    if owner_id != CurrentUser.user.id && to.dmail_filter.try(:filtered?, self)
      self.is_deleted = true
    end
  end

  def update_recipient
    unless is_deleted
      to.update_attribute(:has_mail, true)
    end
  end

  def visible_to?(user)
    user.is_moderator? || owner_id == user.id
  end

  def hidden_attributes
    super + [:message_index]
  end
end
