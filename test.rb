require 'rubygems'
require 'test/unit'
require File.join(File.dirname(__FILE__), 'app')

class TestStudent < Test::Unit::TestCase
  def setup
    @s1 = Student.new :pass_type => "class_package", :class_qty => "10"
    @s2 = Student.new :pass_type => "monthly", :created_on => "10"

  end
  def test_remaining_classes
    2.times { @s1.visits << Visit.new }
    assert_equal(8, @s1.remaining_classes)
  end

  def test_pass_expiry
    
  end
end
