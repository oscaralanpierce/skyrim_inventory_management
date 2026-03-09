# frozen_string_literal: true

class MakeRecipesCanonicalIngredientsPolymorphic < ActiveRecord::Migration[7.1]
  def up
    # Remove foreign key constraint tying recipe_id to a specific table
    remove_foreign_key :recipes_canonical_ingredients, column: :recipe_id

    # Add the recipe_type column - this will form a composite index with recipe_id
    # now that the model is polymorphic, since just the recipe_id could correspond to
    # both a Book and a Canonical::Book
    add_column :recipes_canonical_ingredients, :recipe_type, :string

    # Remove the unique composite index on recipe_id and ingredient_id, since the
    # index will now have to incorporate recipe_type in order to correctly establish
    # a unique relationship between ingredient and recipe.
    remove_index :recipes_canonical_ingredients, columns: %i[recipe_id ingredient_id], unique: true, name: 'index_can_books_ingredients_on_recipe_and_ingredient'
    add_index :recipes_canonical_ingredients, %i[recipe_id recipe_type ingredient_id], unique: true, name: 'index_recipes_can_ingredients_on_recipe_and_ingredient'

    # Populate the recipe_type column on all existing models - since the recipe_id
    # previously only referred to the canonical_books table, this value can be
    # Canonical::Book for all existing models.

    # rubocop:disable Rails/SkipsModelValidations
    RecipesCanonicalIngredient.update_all(recipe_type: 'Canonical::Book')
    # rubocop:enable Rails/SkipsModelValidations

    # Now that the recipe_type column has been populated on all models, we can
    # add a NOT NULL constraint.
    change_column_null :recipes_canonical_ingredients, :recipe_type, false
  end

  def down
    add_foreign_key :recipes_canonical_ingredients, :canonical_books, column: :recipe_id

    remove_index :recipes_canonical_ingredients, columns: %i[recipe_id recipe_type ingredient_id], unique: true, name: 'index_recipes_can_ingredients_on_recipe_and_ingredient'

    remove_column :recipes_canonical_ingredients, :recipe_type

    add_index :recipes_canonical_ingredients, %i[recipe_id ingredient_id], unique: true, name: 'index_can_books_ingredients_on_recipe_and_ingredient'
  end
end
