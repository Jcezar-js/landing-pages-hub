class ApplicationController < ActionController::Base
  before_action :authenticate_admin!

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
