# -*- encoding : utf-8 -*-
module RelicsHelper
  def thank_you_note
    [
      "Dzięki Tobie Cyfrowy Czyn Społeczny działa :)",
      "Zabytki są Ci wdzięczne :)",
      "Cieszymy się, że otwierasz z nami zabytki :)",
      "Zabytki lubią być otwarte. Dziękujemy! :)",
      "Jesteś naszym zabytkowym aniołem :)",
      "Od zabytków głowa nie boli :) Dziękujemy!",
      "Każdy sprawdzony zabytek to krok do sukcesu akcji. Dziękujemy :)",
      "Miło, że poświęcasz swój czas na otwieranie zabytków :)",
      "Zabytki leżą nam na sercu :) Doceniamy, że bierzesz udział w akcji.",
      "Kolejny sprawdzony zabytek :) Ale fajnie!",
      "Dziękujemy! Im nas więcej, tym lepiej :)"
    ].sample
  end

  def categories_facets_hash_for(relics = relics)
    relics.terms('categories', true).inject({}) {|m, t| m[t['term']] = t['count']; m}
  end

  def categories_facets_hash
    return @categories_facets_hash if defined? @categories_facets_hash
    @categories_facets_hash = categories_facets_hash_for(relics)
  end

  def descendants_select(relic, form)
    form.input :relic_id, as: :select, label: t('common.apply_to'), include_blank: false, required: false, 
      collection: relic.root.descendants.created.order('identification').
        map {|d| [d.identification, d.id] }.
        insert(0, [t('activerecord.attributes.relic.relic_group'), relic.id])
  end

  def state_facets
    labels = t('activerecord.attributes.relic.states').with_indifferent_access
    relics.terms('state', true).map do |t|
      ["#{labels[t['term']]} <span class='box'>#{t['count']}</span>".html_safe, t['term']]
    end
  end

  def existence_facets
    labels = t('activerecord.attributes.relic.existences').with_indifferent_access
    relics.terms('existence', true).map do |t|
      ["<span class='label'>#{labels[t['term']]}</span> <span class='box'>#{t['count']}</span>".html_safe, t['term']]
    end
  end

  def has_photos_facets
    labels = t('activerecord.attributes.relic.photos_facets').with_indifferent_access
    relics.terms('has_photos', true).map do |t|
      ["#{labels[t['term']]} <span class='box'>#{t['count']}</span>".html_safe, t['term']]
    end
  end

  def has_description_facets
    labels = t('activerecord.attributes.relic.description_facets').with_indifferent_access
    relics.terms('has_description', true).map do |t|
      ["#{labels[t['term']]} <span class='box'>#{t['count']}</span>".html_safe, t['term']]
    end
  end

  def disabled search, name
    key = "#{search.object_id}_#{name}"
    return @disabled if @disabled && @disabled[key]
    @disabled ||= {}
    @disabled[key] ||= relics.terms(name).inject([]) { |r, t|
      r <<  t['term'] if  t['count'].zero?
      r
    } - search.send(name)
  end

  def order_collection
    [
      [t('views.relics.index.order.score'), 'score.desc'],
      [t('views.relics.index.order.az'), 'alfabethic.asc'],
      [t('views.relics.index.order.za'), 'alfabethic.desc'],
    ]
  end

  def link_to_section_tab(name)
    link_to_unless_current "<span>#{t "relic_tabs." + name.to_s + ".name"}</span>".html_safe, edit_section_relic_path(relic.id, name), :remote => true
  end

  def leafs_of(tree)
    case tree
      when Hash
        tree.map do |k,v|
          if v.blank? || v.empty?
            [k]
          else
            leafs_of(v)
          end
        end.flatten
      when Array
        tree.map { |v| leafs_of(v) }.flatten
      else
        [tree]
    end
  end

  def state_tag(relic)
    labels = t('activerecord.attributes.relic.states').with_indifferent_access
    content_tag :div, :class => 'tag' do
      content_tag :span, labels[relic.state], :class => relic.state
    end
  end

  def state_hint_tag(state, social = false)
    [
      (content_tag :div, :class => "tag" do
        content_tag(:span, t("views.relics.index.states.#{state}.header"), :class => state)
      end),
      content_tag(:div, t("views.relics.index.states.#{state}.info#{'_social' if social}"), :class => "text")
    ].join.html_safe
  end

  def format_localization(relic, reverse=nil)
    a = []
    if relic.foreign_relic?
      a = [relic.country, relic.fprovince, relic.fplace, relic.street]
    else
      if reverse.nil? 
        a << relic.voivodeship.name
        a << "pow. #{relic.district.name}"
        a << "gm. #{relic.commune.name}"
        a << [relic.place.name, relic.street].compact.join(' ')
      else
        a << "województwo #{relic.voivodeship.name}"
        a << "powiat #{relic.district.name}"
        a << "gmina #{relic.commune.name}"
        a << relic.place.name
      end
    end
    reverse.nil? ? a.reject(&:blank?).join(' » ') : a.reject(&:blank?).reverse.join(", ")
  end

  def kind_of_change(revision)
    changed_fields = revision.changeset.keys
    changed_fields.map do |k|
      t("views.pages.home.revision_change.#{k}")
    end.compact.join(', ')
  end

  def relic_stats
    return @relic_stats if defined? @relic_stats
    @relic_stats = {
      :unchecked  => Relic.created.where(:state => 'unchecked').count,
      :checked    => Relic.created.where(:state => 'checked').count,
      :filled     => Relic.created.where(:state => 'filled').count,
      :total      => Relic.created.count
    }
  end

  def polish_places(relic)
    if relic.try(:commune)
      relic.commune.places.not_custom
    else
      Place.not_custom.limit(100)
    end
  end

  def path_to_polygon(path)
    path
  end

  def original_relic_path(relic)
    relic_path(relic.id, :original => true)
  end
end
