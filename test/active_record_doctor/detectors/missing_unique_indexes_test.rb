# frozen_string_literal: true

class ActiveRecordDoctor::Detectors::MissingUniqueIndexesTest < Minitest::Test
  def test_missing_unique_index
    create_table(:users) do |t|
      t.string :email
      t.index :email
    end.create_model do
      validates :email, uniqueness: true
    end

    assert_success(<<OUTPUT)
The following indexes should be created to back model-level uniqueness validations:
  users: email
OUTPUT
  end

  def test_present_unique_index
    create_table(:users) do |t|
      t.string :email
      t.index :email, unique: true
    end.create_model do
      validates :email, uniqueness: true
    end

    assert_success("")
  end

  def test_missing_unique_index_with_scope
    create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email]
    end.create_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    assert_success(<<OUTPUT)
The following indexes should be created to back model-level uniqueness validations:
  users: company_id, department_id, email
OUTPUT
  end

  def test_present_unique_index_with_scope
    create_table(:users) do |t|
      t.string :email
      t.integer :company_id
      t.integer :department_id
      t.index [:company_id, :department_id, :email], unique: true
    end.create_model do
      validates :email, uniqueness: { scope: [:company_id, :department_id] }
    end

    assert_success("")
  end

  def test_column_order_is_ignored
    create_table(:users) do |t|
      t.string :email
      t.integer :organization_id

      t.index [:email, :organization_id], unique: true
    end.create_model do
      validates :email, uniqueness: { scope: :organization_id }
    end

    assert_success("")
  end

  def test_conditions_is_skipped
    assert_skipped(conditions: -> { where.not(email: nil) })
  end

  def test_case_insensitive_is_skipped
    assert_skipped(case_sensitive: false)
  end

  def test_if_is_skipped
    assert_skipped(if: ->(_model) { true })
  end

  def test_unless_is_skipped
    assert_skipped(unless: ->(_model) { true })
  end

  def test_skips_validator_without_attributes
    create_table(:users) do |t|
      t.string :email
      t.index :email
    end.create_model do
      validates_with DummyValidator
    end

    assert_success("")
  end

  class DummyValidator < ActiveModel::Validator
    def validate(record)
    end
  end

  private

  def assert_skipped(options)
    create_table(:users) do |t|
      t.string :email
    end.create_model do
      validates :email, uniqueness: options
    end

    assert_success("")
  end
end
