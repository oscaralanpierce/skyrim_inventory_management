# frozen_string_literal: true

class Book < InGameItem
  belongs_to :canonical_book, optional: true, class_name: 'Canonical::Book', inverse_of: :books

  has_many :recipes_canonical_ingredients, dependent: :destroy, inverse_of: :recipe, foreign_key: 'recipe_id'
  has_many :canonical_ingredients, through: :recipes_canonical_ingredients, class_name: 'Canonical::Ingredient', source: :ingredient

  validates :title, presence: true

  def canonical_model
    canonical_book
  end

  def canonical_models
    return Canonical::Book.where(id: canonical_book_id) if canonical_model_matches?

    canonicals = Canonical::Book.where('title ILIKE :title OR :title ILIKE ANY(title_variants)', title:)
    canonicals = canonicals.where(**attributes_to_match) if attributes_to_match.any?

    return canonicals if canonicals.none? || canonical_ingredients.none?

    recipes_canonical_ingredients.each {|join_model| canonicals = canonicals.joins(:recipes_canonical_ingredients).where(recipes_canonical_ingredients: { ingredient_id: join_model.ingredient_id }) }

    Canonical::Book.where(id: canonicals.ids)
  end

  def recipe?
    canonical_models.where(book_type: 'recipe').any?
  end

  private

  alias_method :canonical_model=, :canonical_book=

  def canonical_class
    Canonical::Book
  end

  def canonical_table
    'canonical_books'
  end

  def canonical_model_id
    canonical_book_id
  end

  def canonical_model_id_changed?
    canonical_book_id_changed?
  end

  def inverse_relationship_name
    :books
  end

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.title = canonical_model.title
    self.authors = canonical_model.authors
    self.unit_weight = canonical_model.unit_weight
    self.skill_name = canonical_model.skill_name
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless title.casecmp(canonical_model.title).zero? || title_matches_variant?
    return false unless unit_weight.nil? || unit_weight == canonical_model.unit_weight
    return false unless skill_name.nil? || skill_name == canonical_model.skill_name

    true
  end

  def title_matches_variant?
    canonical_model&.title_variants&.any? {|variant| title.casecmp(variant).zero? }
  end

  def attributes_to_match
    { authors: authors.presence, unit_weight:, skill_name: }.compact
  end
end
