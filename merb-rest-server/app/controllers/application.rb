class MerbRestServer::Application < Merb::Controller
  include Merb::AuthenticatedHelper
  
  controller_for_slice
  
end