require 'spec_helper'
require 'honeycomb/ir'


describe Honeycomb::IR do
  let(:example_file){'spec/outputs/rspec.res'}
  context "Loading in IR files" do
    describe ".load" do
      it 'loads in a cucumber IR results file' do
        Honeycomb::IR.load( example_file )
      end
    end
  end

  context "Handling rspec IR generated by Hive-Results gem" do
    
    let(:ir) { Honeycomb::IR.load( example_file ) }

    describe "#tests" do

      it 'returns an array of just the test portions of the json' do
        expect(ir.tests).to be_a Array
        expect(ir.tests.count).to eq 11
      end

      it 'only includes actual test as tests' do
        node_types = ir.tests.collect { |t| t[:type] }.uniq!
        expect(node_types).to eq [ 'Rspec::Test' ]
      end
      
    end

    describe "#count" do
      it "Can pick out the passing tests from the run" do
        expect(ir.count(:passed)).to eq 8
      end

      it "Can pick out the failing tests from the run" do
        expect(ir.count(:failed)).to eq 3
      end

      it "Can identify there were no tests of an unknown type" do
        expect(ir.count(:unknown)).to eq 0
      end
    end

    describe "flat_format" do
      it "Returns the results as a flat array" do
        expect(ir.flat_format).to be_a Array
      end
    end
  end

end
