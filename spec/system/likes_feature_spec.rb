require "rails_helper"

RSpec.describe "Likes Feature" do
  let!(:guide_user) { create(:user, role: :guide, name: "Test Guide") }
  let!(:guide_profile) { create(:guide_profile, user: guide_user) }
  let!(:tourist1) { create(:user, role: :tourist, name: "Tourist One", email: "tourist1@test.com") }
  let!(:tourist2) { create(:user, role: :tourist, name: "Tourist Two", email: "tourist2@test.com") }
  let!(:tourist3) { create(:user, role: :tourist, name: "Tourist Three", email: "tourist3@test.com") }

  # Create a past tour so tourists can comment
  let!(:past_tour) do
    create(:tour,
           guide: guide_user,
           starts_at: 10.days.ago,
           ends_at: 10.days.ago + 3.hours)
  end

  # Create bookings so tourists can comment
  let!(:booking1) { create(:booking, user: tourist1, tour: past_tour, status: :confirmed) }
  let!(:booking2) { create(:booking, user: tourist2, tour: past_tour, status: :confirmed) }
  let!(:booking3) { create(:booking, user: tourist3, tour: past_tour, status: :confirmed) }

  # Create comments from tourists who have bookings
  let!(:comment1) do
    create(:comment,
           user: tourist1,
           guide_profile:,
           content: "Great guide! Very knowledgeable and friendly.")
  end

  let!(:comment2) do
    create(:comment,
           user: tourist2,
           guide_profile:,
           content: "Amazing tour experience. Highly recommend!")
  end

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "Liking comments" do
    context "when user is signed in as tourist1" do
      before do
        sign_in tourist1
        visit guide_profile_path(guide_profile)
      end

      it "allows user to like another tourist's comment" do
        # Find tourist2's comment
        comment_section = find("#comment_#{comment2.id}")

        expect(comment_section).to have_content("Tourist Two")
        expect(comment_section).to have_content(comment2.content)

        # Initially, the comment should have 0 likes - look for the button with emoji and count
        within comment_section do
          expect(page).to have_button
        end

        # Like the comment - find button by CSS selector
        within comment_section do
          find("button").click
        end

        # Wait for Turbo to update the DOM
        sleep 1

        # Check that the like was registered
        expect(Like.where(user: tourist1, comment: comment2).count).to eq(1)

        # Reload to verify persistence
        visit guide_profile_path(guide_profile)

        # Should now show 1 like
        comment_section = find("#comment_#{comment2.id}")
        within comment_section do
          expect(page).to have_content("❤️")
          expect(page).to have_content("1")
        end
      end

      it "allows user to unlike a comment they previously liked" do
        # First, create a like
        Like.create!(user: tourist1, comment: comment2)

        visit guide_profile_path(guide_profile)

        comment_section = find("#comment_#{comment2.id}")

        # Should show liked state
        expect(comment_section).to have_button("❤️ 1")

        # Unlike the comment
        within comment_section do
          click_button "❤️ 1"
        end

        # Wait for the page to update
        sleep 0.5

        # Check that the like was removed
        expect(Like.where(user: tourist1, comment: comment2).count).to eq(0)

        # Reload to verify persistence
        visit guide_profile_path(guide_profile)

        # Should now show 0 likes with empty heart
        comment_section = find("#comment_#{comment2.id}")
        expect(comment_section).to have_button("🤍 0")
      end

      it "allows user to like their own comment" do
        comment_section = find("#comment_#{comment1.id}")

        expect(comment_section).to have_content("Tourist One")

        # Like own comment
        within comment_section do
          click_button "🤍 0"
        end

        sleep 0.5

        # Check that the like was registered
        expect(Like.where(user: tourist1, comment: comment1).count).to eq(1)
      end

      it "allows user to like multiple comments" do
        # Like comment1
        within "#comment_#{comment1.id}" do
          click_button "🤍 0"
        end

        sleep 0.3

        # Like comment2
        within "#comment_#{comment2.id}" do
          click_button "🤍 0"
        end

        sleep 0.5

        # Both likes should be registered
        expect(Like.where(user: tourist1, comment: comment1).count).to eq(1)
        expect(Like.where(user: tourist1, comment: comment2).count).to eq(1)
      end
    end

    context "when user is not signed in" do
      before do
        visit guide_profile_path(guide_profile)
      end

      it "displays like counts but does not show like buttons" do
        # Create some likes
        Like.create!(user: tourist1, comment: comment1)
        Like.create!(user: tourist2, comment: comment1)

        visit guide_profile_path(guide_profile)

        comment_section = find("#comment_#{comment1.id}")

        # Should show like count but not as a button
        expect(comment_section).to have_content("2 likes")
        expect(comment_section).not_to have_button
      end
    end

    context "when multiple users like the same comment" do
      it "correctly counts likes from different users" do
        # Create likes from all three tourists
        Like.create!(user: tourist1, comment: comment1)
        Like.create!(user: tourist2, comment: comment1)
        Like.create!(user: tourist3, comment: comment1)

        sign_in tourist1
        visit guide_profile_path(guide_profile)

        comment_section = find("#comment_#{comment1.id}")

        # Should show 3 likes total
        expect(comment_section).to have_button("❤️ 3")

        # Tourist1 unlikes
        within comment_section do
          click_button "❤️ 3"
        end

        sleep 0.5

        # Should now show 2 likes and empty heart for tourist1
        visit guide_profile_path(guide_profile)
        comment_section = find("#comment_#{comment1.id}")
        expect(comment_section).to have_button("🤍 2")
      end
    end

    context "counter cache" do
      it "properly updates the likes_count column" do
        expect(comment1.likes_count).to eq(0)

        Like.create!(user: tourist1, comment: comment1)
        comment1.reload

        expect(comment1.likes_count).to eq(1)

        Like.create!(user: tourist2, comment: comment1)
        comment1.reload

        expect(comment1.likes_count).to eq(2)

        Like.find_by(user: tourist1, comment: comment1).destroy
        comment1.reload

        expect(comment1.likes_count).to eq(1)
      end
    end
  end

  describe "Like restrictions" do
    it "prevents duplicate likes from the same user" do
      Like.create!(user: tourist1, comment: comment1)

      # Try to create another like
      duplicate_like = Like.new(user: tourist1, comment: comment1)

      expect(duplicate_like.valid?).to be false
      expect(duplicate_like.errors[:user]).to include("can only like a comment once")
    end

    it "allows different users to like the same comment" do
      Like.create!(user: tourist1, comment: comment1)
      like2 = Like.new(user: tourist2, comment: comment1)

      expect(like2.valid?).to be true
    end

    it "allows the same user to like different comments" do
      Like.create!(user: tourist1, comment: comment1)
      like2 = Like.new(user: tourist1, comment: comment2)

      expect(like2.valid?).to be true
    end
  end

  describe "Like persistence" do
    it "maintains likes across page refreshes" do
      sign_in tourist1
      visit guide_profile_path(guide_profile)

      # Like a comment
      within "#comment_#{comment1.id}" do
        click_button "🤍 0"
      end

      sleep 0.5

      # Refresh the page
      visit guide_profile_path(guide_profile)

      # Like should still be there
      expect(page).to have_button("❤️ 1")
    end

    it "persists likes even when navigating away and back" do
      sign_in tourist1
      visit guide_profile_path(guide_profile)

      within "#comment_#{comment1.id}" do
        click_button "🤍 0"
      end

      sleep 0.5

      # Navigate away
      visit root_path

      # Navigate back
      visit guide_profile_path(guide_profile)

      # Like should still be there
      expect(page).to have_button("❤️ 1")
    end
  end

  describe "Any user can like any comment" do
    context "when user has no booking with the guide" do
      let!(:tourist_no_booking) do
        create(:user, role: :tourist, name: "Tourist No Booking", email: "nobooking@test.com")
      end

      it "allows user to like comments even without bookings with the guide" do
        sign_in tourist_no_booking
        visit guide_profile_path(guide_profile)

        # Should be able to see and like comments
        within "#comment_#{comment1.id}" do
          click_button "🤍 0"
        end

        sleep 0.5

        expect(Like.where(user: tourist_no_booking, comment: comment1).count).to eq(1)
      end

      it "prevents user from commenting without bookings but allows liking" do
        sign_in tourist_no_booking
        visit guide_profile_path(guide_profile)

        # Should not be able to comment
        expect(page).to have_content("You can only comment on guides you have booked tours with")

        # But should be able to like
        within "#comment_#{comment1.id}" do
          click_button "🤍 0"
        end

        sleep 0.5

        expect(Like.where(user: tourist_no_booking, comment: comment1).count).to eq(1)
      end
    end
  end
end
