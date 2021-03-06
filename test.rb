require 'rubygems'
require 'test/unit'
require File.join(File.dirname(__FILE__), 'app')

class TestStudent < Test::Unit::TestCase
  def setup
    @time = Time.now - 3.weeks
    @months = 1 
    @s1 = Student.new 
    @p1 = Pass.new :pass_type => "class_package", :class_qty => "10"
    @s1.pass = @p1
    @s2 = Student.new 
    @p2 = Pass.new :pass_type => "monthly", :created_on => @time, :month_qty => @months
    @s2.pass = @p2
  end

  def test_remaining_classes
    2.times { @s1.visits << Visit.new }
    assert_equal 8, @s1.pass.remaining_classes
  end

  def test_pass_expiry
    assert_equal (@time + 1.month ).to_date, @s2.pass.expiry
  end
end
