require "rails_helper"

RSpec.describe ReviewPolicy do
  subject(:policy) { described_class }

  let(:admin) { create(:user, :admin) }
  let(:guide) { create(:user, :guide) }
  let(:tourist) { create(:user, :tourist) }
  let(:other_tourist) { create(:user, :tourist) }
  let(:done_tour) { create(:tour, guide:, status: :done) }
  let(:scheduled_tour) { create(:tour, guide:, status: :scheduled) }
  let(:booking) { create(:booking, tour: done_tour, user: tourist) }
  let(:review) { build(:review, booking:, tour: done_tour, user: tourist) }

  permissions :create? do
    it "allows admin to create any review" do
      expect(policy).to permit(admin, review)
    end

    it "allows tourist to create review for their own done tour" do
      expect(policy).to permit(tourist, review)
    end

    it "denies tourist from creating review for tour not done" do
      scheduled_review = build(:review, tour: scheduled_tour, user: tourist)
      expect(policy).not_to permit(tourist, scheduled_review)
    end

    it "denies other tourists from creating review" do
      other_review = build(:review, booking:, tour: done_tour, user: other_tourist)
      expect(policy).not_to permit(other_tourist, other_review)
    end

    it "denies guides from creating reviews" do
      expect(policy).not_to permit(guide, review)
    end
  end

  permissions :update?, :edit? do
    let(:saved_review) { create(:review, booking:, tour: done_tour, user: tourist) }

    it "allows admin to update any review" do
      expect(policy).to permit(admin, saved_review)
    end

    it "allows tourist to update their own review" do
      expect(policy).to permit(tourist, saved_review)
    end

    it "denies other tourists from updating the review" do
      expect(policy).not_to permit(other_tourist, saved_review)
    end

    it "denies guides from updating reviews" do
      expect(policy).not_to permit(guide, saved_review)
    end
  end

  permissions :destroy? do
    let(:saved_review) { create(:review, booking:, tour: done_tour, user: tourist) }

    it "allows admin to destroy any review" do
      expect(policy).to permit(admin, saved_review)
    end

    it "allows tourist to destroy their own review" do
      expect(policy).to permit(tourist, saved_review)
    end

    it "denies other tourists from destroying the review" do
      expect(policy).not_to permit(other_tourist, saved_review)
    end

    it "denies guides from destroying reviews" do
      expect(policy).not_to permit(guide, saved_review)
    end
  end

  describe "Scope" do
    let!(:tourist_review) { create(:review, booking:, tour: done_tour, user: tourist) }
    let(:other_booking) { create(:booking, tour: done_tour, user: other_tourist) }
    let!(:other_tourist_review) { create(:review, booking: other_booking, tour: done_tour, user: other_tourist) }

    it "returns all reviews for admin" do
      resolved_scope = ReviewPolicy::Scope.new(admin, Review.all).resolve
      expect(resolved_scope).to include(tourist_review, other_tourist_review)
    end

    it "returns only user's reviews for tourists" do
      resolved_scope = ReviewPolicy::Scope.new(tourist, Review.all).resolve
      expect(resolved_scope).to include(tourist_review)
      expect(resolved_scope).not_to include(other_tourist_review)
    end

    it "returns only user's reviews for other users" do
      resolved_scope = ReviewPolicy::Scope.new(other_tourist, Review.all).resolve
      expect(resolved_scope).to include(other_tourist_review)
      expect(resolved_scope).not_to include(tourist_review)
    end
  end
end
