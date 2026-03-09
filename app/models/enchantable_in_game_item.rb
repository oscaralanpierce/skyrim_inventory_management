# frozen_string_literal: true

class EnchantableInGameItem < InGameItem
  self.abstract_class = true

  has_many :enchantables_enchantments, dependent: :destroy, as: :enchantable
  has_many :enchantments, -> { select 'enchantments.*, enchantables_enchantments.strength as strength' }, through: :enchantables_enchantments, source: :enchantment

  after_create :set_enchantments, if: -> { canonical_model.present? }

  def canonical_models
    return canonical_class.where(id: canonical_model_id) if canonical_model_matches?

    query = 'name ILIKE :name'
    query += ' AND magical_effects ILIKE :magical_effects' if magical_effects.present?

    canonicals = canonical_class.where(query, name:, magical_effects:)
    canonicals = canonicals.where(**attributes_to_match) if attributes_to_match.any?

    return canonicals if canonicals.none? || enchantments.none?

    enchantables_enchantments.added_manually.each do |join_model|
      canonicals = if join_model.strength.present?
                     canonicals.left_outer_joins(:enchantables_enchantments).where("(enchantables_enchantments.enchantment_id = :enchantment_id AND enchantables_enchantments.strength = :strength) OR #{canonical_table}.enchantable = true", enchantment_id: join_model.enchantment_id, strength: join_model.strength)
                   else
                     canonicals.left_outer_joins(:enchantables_enchantments).where("(enchantables_enchantments.enchantment_id = :enchantment_id AND enchantables_enchantments.strength IS NULL) OR #{canonical_table}.enchantable = true", enchantment_id: join_model.enchantment_id)
                   end
    end

    canonical_class.where(id: canonicals.ids)
  end

  private

  def clear_canonical_model
    self.canonical_model = nil
    remove_automatically_added_enchantments!
  end

  def remove_automatically_added_enchantments!
    enchantables_enchantments.added_automatically.find_each(&:destroy!)
  end

  def set_enchantments
    return if canonical_model.enchantments.empty?

    remove_automatically_added_enchantments!

    canonical_model.enchantables_enchantments.each {|model| enchantables_enchantments.find_or_create_by!(enchantment_id: model.enchantment_id, strength: model.strength) {|new_model| new_model.added_automatically = true } }
  end
end
