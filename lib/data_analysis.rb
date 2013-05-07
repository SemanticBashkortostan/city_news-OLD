#coding: utf-8

class DataAnalysis


  def initialize
  end


  def boundary_regexp pattern, position
    case position
      when :right
        Regexp.new "#{pattern}+.([[:word:]]+.[[:word:]]+.[[:word:]]+)"
      when :left
        Regexp.new "([[:word:]]+.[[:word:]]+.[[:word:]]+.)#{pattern}"
      else
        Regexp.new "([[:word:]]+.[[:word:]]+.[[:word:]]+.)#{pattern}+.([[:word:]]+.[[:word:]]+.[[:word:]]+)"
    end
  end


  def find_city_names_boundings
    truly_rules = VocabularyEntry.truly.all
    boundings = {:all => [], :left => [], :right => []}
    feeds = Feed.where('text_class_id is not NULL').all
    feeds.each_with_index do |feed, i|
      puts "Processed #{i}/#{feeds.count}"
      truly_rules.each do |ve|
        left_scanned = feed.string_for_classifier.scan boundary_regexp(ve.regexp_rule, :left)
        right_scanned = feed.string_for_classifier.scan boundary_regexp(ve.regexp_rule, :right)
        scanned = feed.string_for_classifier.scan boundary_regexp(ve.regexp_rule, :all)

        boundings[:all] << scanned if scanned.present?
        boundings[:left] << left_scanned if left_scanned.present?
        boundings[:right] << right_scanned if right_scanned.present?
      end
    end

    return boundings
  end

  def filter_left_and_right_uppercase boundings
    filtered = {:left => [], :right => []}
    boundings.each do |bounds|
      bounds.each do |bound|
        p [bound, bound[0].split.last.first]
        if bound[0].split.last.first == bound[0].split.last.mb_chars.first.upcase
          filtered[:left] << bound
        elsif bound[2].split.last.first == bound[2].split.last.mb_chars.first.upcase
          filtered[:right] << bound
        end
      end
    end
    return filtered
  end


end