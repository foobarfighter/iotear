require "#{File.dirname(__FILE__)}/spec_helper.rb"

describe ThreadPool do
  it "passes" do
    1.should == 1
  end

  it "fails" do
    1.should_not == 1
  end
end