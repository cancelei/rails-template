require "rails_helper"

RSpec.describe "Comments" do
  let(:guide) { FactoryBot.create(:user, :guide) }
  let(:tourist) { FactoryBot.create(:user, :tourist) }
  let(:guide_profile) { FactoryBot.create(:guide_profile, user: guide) }
  let(:comment) { FactoryBot.create(:comment, guide_profile:, user: tourist) }

  describe "Creating comments" do
    before do
      sign_in tourist
      visit guide_profile_path(guide_profile)
    end

    it "allows creating a new comment" do
      fill_in "Comment", with: "This is a test comment"
      click_on "Post Comment"

      expect(page).to have_text("Comment was successfully created")
      expect(page).to have_text("This is a test comment")
    end

    context "when comment content is empty" do
      it "shows validation errors" do
        fill_in "Comment", with: ""
        click_on "Post Comment"

        expect(page).to have_text("can't be blank")
      end
    end

    context "when user is not signed in" do
      before do
        sign_out tourist
        visit guide_profile_path(guide_profile)
      end

      it "does not show comment form" do
        expect(page).to have_no_button("Post Comment")
      end
    end
  end

  describe "Liking and unliking comments" do
    before do
      comment
      sign_in tourist
      visit guide_profile_path(guide_profile)
    end

    it "allows toggling likes on comments" do
      # Initial state - no likes
      within "#comment-#{comment.id}" do
        expect(page).to have_text("0 likes")
      end

      # Like the comment
      within "#comment-#{comment.id}" do
        click_on "Like"
      end

      expect(page).to have_text("1 like")

      # Unlike the comment
      within "#comment-#{comment.id}" do
        click_on "Unlike"
      end

      expect(page).to have_text("0 likes")
    end
  end

  describe "Nested comments" do
    before do
      sign_in tourist
      visit guide_profile_path(guide_profile)
    end

    it "allows replying to a comment" do
      parent_comment = FactoryBot.create(:comment, guide_profile:)
      visit guide_profile_path(guide_profile)

      within "#comment-#{parent_comment.id}" do
        click_on "Reply"
        fill_in "Comment", with: "This is a reply"
        click_on "Post Reply"
      end

      expect(page).to have_text("This is a reply")
      expect(Comment.last.parent_id).to eq(parent_comment.id)
    end
  end

  describe "Comment display" do
    let!(:comments) { FactoryBot.create_list(:comment, 5, guide_profile:) }

    before do
      visit guide_profile_path(guide_profile)
    end

    it "displays all comments for the guide profile" do
      expect(page).to have_css(".comment", count: 5)
    end

    it "shows comment author and timestamp" do
      comment = comments.first
      within "#comment-#{comment.id}" do
        expect(page).to have_text(comment.user.name)
        expect(page).to have_text(comment.created_at.strftime("%b %d, %Y"))
      end
    end
  end
end
