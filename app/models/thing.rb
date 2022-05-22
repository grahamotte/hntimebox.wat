# frozen_string_literal: true

class Thing < ApplicationRecord
  def self.upsert_things(things)
    return if things.blank?

    names = column_names.map(&:to_sym)
    template = names.map { |x| [x, nil] }.to_h

    things
      .map { |x| template.merge(x) }
      .map { |x| x.slice(*names) }
      .then { |x| Thing.upsert_all(x, unique_by: :id) }
  end
end
