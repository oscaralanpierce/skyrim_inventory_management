# frozen_string_literal: true

# TL;DR: It is a practical impossibility to capitalise strings in a way that
# adheres to any particular style guide. This module is a step up from the
# ActiveSupport String#titleize method, which capitalises every word in the
# string, but it does not handle edge cases such as when the part of speech
# of a word is dependent on its usage in a sentence.
#
# This module properly title cases strings. ActiveSupport's #titleize method
# for strings is elegant but has an issue: it capitalises the first letter of
# every word in the string. Actual headline capitalisation rules are more
# complex and depend on the style guide (see https://headlinecapitalization.com/).
# However, there are a few commonalities:
#   * The first word of the title is capitalised
#   * The last word in the title is capitalised
#   * Important words are capitalised
#
# Which words are considered important is a point of contention but the rule of
# thumb is that they should be included if they are:
#   * Adjectives
#   * Adverbs
#   * Nouns
#   * Verbs (whether forms of 'to be', such as 'is', 'was', and 'were', count is
#     debated)
#   * Subordinating conjunctions ('as', 'so' 'that')
#
# Articles ('a', 'an', 'the'), coordinating conjunctions ('and', 'but', 'for'),
# and prepositions less than 5 words are generally not included.
#
# The rules are also subjective. For example, while the forms of 'to be' should
# be capitalised according to most style guides, seeing 'Is' capitalised and 'in'
# not doesn't look right to many people's eyes.
#
# There's also the issue of words with more than one meaning belonging to different
# parts of speech. For example, 'then' can be a conjunction or an adverb depending
# on usage ("If you see it that way, then we shouldn't go" = subordinating conjunction;
# "If you won't be ready till tomorrow, we'll just go then" = adverb). Another
# relevant example is 'like', which can be, depending on usage, a:
#   * Verb ("I like her")
#   * Adverb ("We drove was like 750 miles")
#   * Preposition ("You're old like me")
#   * Conjunction ("He felt like he'd been punched in the stomach")
#
# Sadly, this module does not cover all these edge cases. In particular, the issue
# of words belonging to multiple parts of speech could only be solved with complex
# logic and possibly even with natural language processing powered by an AI model.
# I'm not doing that.
#
# Instead, I'm creating a list of commonly not-capitalised words and making sure
# the #title_from_string method does not capitalise them unless they are the first
# or last word in the title. Words that belong to multiple parts of speech are
# excluded from the list unless they are three characters or less.

module Titlecase
  LOWERCASE_WORDS = %w[a an the and but for at by from with to in of into onto on without within].freeze

  module_function

  def titleize(string)
    words = string.downcase.split(' ')

    words.map.with_index(1) do |word, index|
      LOWERCASE_WORDS.include?(word) && [1, words.length].exclude?(index) ? word : word.capitalize
    end.join(' ')
  end
end
