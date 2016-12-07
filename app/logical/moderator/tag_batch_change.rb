module Moderator
  class TagBatchChange < Struct.new(:antecedent, :consequent, :updater_id, :updater_ip_addr)
    class Error < Exception ; end

    def perform
      raise Error.new("antecedent is missing") if antecedent.blank?

      normalized_antecedent = TagAlias.to_aliased(::Tag.scan_tags(antecedent.mb_chars.downcase))
      normalized_consequent = TagAlias.to_aliased(::Tag.scan_tags(consequent.mb_chars.downcase))

      updater = User.find(updater_id)

      CurrentUser.without_safe_mode do
        CurrentUser.scoped(updater, updater_ip_addr) do
          ModAction.create(:description => "processed mass update: #{antecedent} -> #{consequent}")

          ::Post.tag_match(antecedent).where("true /* Moderator::TagBatchChange#perform */").find_each do |post|
            post.reload
            tags = (post.tag_array - normalized_antecedent + normalized_consequent).join(" ")
            post.update_attributes(:tag_string => tags)
          end

          tags = Tag.scan_tags(antecedent, :strip_metatags => true)
          conds = tags.map {|x| "tag_query like ?"}.join(" AND ")
          conds = [conds, *tags.map {|x| "%#{x}%"}]
          SavedSearch.where(*conds).find_each do |ss|
            ss.tag_query = (ss.tag_query_array - tags + antecedent).uniq.join(" ")
            ss.save
          end

        end
      end
    end
  end
end
