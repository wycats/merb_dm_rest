Merb::Config.use { |c|
  # c[:exception_details] = true
  c[:log_auto_flush ] = true
  c[:log_level] = :debug

  # c[:log_stream] = STDOUT
  # Or redirect logging into a file:
  # c[:log_file]  = Merb.root / "log" / "development.log"
}