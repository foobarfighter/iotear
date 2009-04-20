require "#{File.dirname(__FILE__)}/spec_helper"

describe IOTear::Selector do
  attr_reader :enumerable
  before do
    @enumerable = [1, 2, 3]
  end

  describe "#initialize" do
    describe "when the argument is Enumerable" do
      it "sets #enumerable" do
        IOTear::Selector.new(enumerable).enumerable.should == enumerable
      end

      it "initializes the #current_index to -1" do
        IOTear::Selector.new(enumerable).current_index.should == -1
      end
    end

    describe "when the argument is not Enumerable" do
      it "raises ArgumentError" do
        lambda { IOTear::Selector.new(0) }.should raise_error ArgumentError
      end
    end
  end

  describe "#current" do
    attr_reader :selector
    before do
      @selector = IOTear::Selector.new(enumerable)
    end

    describe "when the Selector has not previously retrieved items" do
      before do
        selector.current_index.should == -1
      end

      describe "when the Enumerable is not empty" do
        it "retrieves the first item in the Enumerable" do
          selector.current == enumerable[selector.current_index]
        end
      end

      describe "when the Enumerable is empty" do
        before do
          @enumerable = []
          @selector = IOTear::Selector.new(enumerable)
          selector.current_index.should == -1
        end

        it "returns nil" do
          selector.current.should == nil
        end
      end
    end

    describe "when the Selector has previously retrieved items" do
      attr_reader :expected_index
      before do
        selector.get
        selector.get
        @expected_index = 1
        selector.current_index.should == expected_index
      end

      it "retrieves the current item in the enumerable" do
        selector.current.should == enumerable[expected_index]
      end
    end
  end

  describe "#get" do
    attr_reader :selector
    before do
      @selector = IOTear::Selector.new(enumerable)
    end

    describe "when #current_index is less than the size of the enumerable" do
      attr_reader :expected_current_index
      before do
        @expected_current_index = selector.current_index + 1
        selector.current_index.should < enumerable.size
      end
      it "increases the #current_index" do
        selector.get
        selector.current_index.should == expected_current_index
      end

      it "returns the next object in the enumerable" do
        selector.get
        selector.current.should == enumerable[expected_current_index]
      end
    end

    describe "when the Selector's #current_index is the last item of the enumerable" do
      before do
        (enumerable.size).times do
          selector.get
        end
        selector.should be_last
      end

      it "retrieves the first item in the enumerable" do
        selector.get.should == enumerable.first
      end
    end
  end

  describe "#last?" do
    attr_reader :selector
    before do
      @selector = IOTear::Selector.new(enumerable)
    end

    describe "when the Selector has selecting the last element in the enumerable" do
      before do
        (enumerable.size).times do
          selector.get
        end
      end

      it "returns true" do
        selector.should be_last
      end
    end

    describe "when the Selector selected any other element in the enumerable" do
      it "returns false" do
        selector.should_not be_last
      end
    end

    describe "when the enumerable has no items" do
      before do
        @selector = IOTear::Selector.new([])
      end

      it "returns true" do
        selector.should be_last
      end
    end
  end
end