class AssertionFailed < StandardError; end

def assert!(&blk)
  raise AssertionFailed unless yield
end
