require "rails_helper"

RSpec.describe "Guide Profiles" do
  let(:guide) { FactoryBot.create(:user, :guide) }
  let(:guide_profile) { FactoryBot.create(:guide_profile, user: guide) }

  describe "Viewing a guide profile" do
    before do
      guide_profile
      visit guide_profile_path(guide_profile)
    end

    it_behaves_like "an accessible page"

    it "displays guide profile information" do
      expect(page).to have_text(guide_profile.bio)
      expect(page).to have_text(guide.name)
    end

    it "displays guide's tours" do
      tour = FactoryBot.create(:tour, guide:)
      visit guide_profile_path(guide_profile)

      expect(page).to have_text(tour.title)
    end

    it "displays reviews" do
      review = FactoryBot.create(:review, guide_profile:)
      visit guide_profile_path(guide_profile)

      expect(page).to have_text(review.comment)
      expect(page).to have_text("Rating: #{review.rating}")
    end
  end

  describe "Creating a guide profile" do
    before do
      sign_in guide
      visit new_guide_profile_path
    end

    it_behaves_like "an accessible page"

    it "allows a guide to create their profile" do
      fill_in "Bio", with: "Experienced mountain guide with 10 years of expertise"
      fill_in "Certifications", with: "Wilderness First Responder, AMGA Certified"
      fill_in "Languages", with: "English, Spanish, French"
      fill_in "Years of experience", with: "10"

      click_on "Create Guide profile"

      expect(page).to have_text("Guide profile was successfully created")
      expect(page).to have_text("Experienced mountain guide")
    end
  end

  describe "Editing a guide profile" do
    before do
      guide_profile
      sign_in guide
      visit edit_guide_profile_path(guide_profile)
    end

    it_behaves_like "an accessible page"

    it "allows a guide to edit their profile" do
      fill_in "Bio", with: "Updated bio information"
      click_on "Update Guide profile"

      expect(page).to have_text("Guide profile was successfully updated")
      expect(page).to have_text("Updated bio information")
    end
  end

  describe "Comments on guide profiles" do
    before do
      guide_profile
      sign_in FactoryBot.create(:user, :tourist)
      visit guide_profile_path(guide_profile)
    end

    it "allows signed-in users to leave comments" do
      fill_in "Comment", with: "Great guide, very knowledgeable!"
      click_on "Post Comment"

      expect(page).to have_text("Comment was successfully created")
      expect(page).to have_text("Great guide, very knowledgeable!")
    end

    context "when commenting on existing comment" do
      let(:comment) { FactoryBot.create(:comment, guide_profile:) }

      before do
        comment
        visit guide_profile_path(guide_profile)
      end

      it "allows liking a comment" do
        within "#comment-#{comment.id}" do
          click_on "Like"
        end

        expect(page).to have_text("1 like")
      end

      it "allows unliking a comment" do
        comment.likes.create!(user: User.last)
        visit guide_profile_path(guide_profile)

        within "#comment-#{comment.id}" do
          click_on "Unlike"
        end

        expect(page).to have_text("0 likes")
      end
    end
  end
end
