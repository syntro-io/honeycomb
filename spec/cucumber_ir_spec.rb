require 'spec_helper'
require 'honeycomb/ir'
require 'json'

EXAMPLE_FILE = 'spec/outputs/cucumber.res'

describe Honeycomb::IR do

  context "Loading in IR files" do
    describe ".load" do
      it 'loads in a cucumber IR results file' do
        Honeycomb::IR.load(EXAMPLE_FILE)
      end
    end
  end

  context "Handling cucumber IR generated by Hive-Results gem" do

    let(:ir) { Honeycomb::IR.load( EXAMPLE_FILE ) }

    describe "#tests" do

      it 'returns an array of just the test portions of the json' do
        expect(ir.tests).to be_a Array
        expect(ir.tests.count).to eq 17
      end

      it 'only includes Scenarios and Scenario outline examples as tests' do
        node_types = ir.tests.collect { |t| t[:type] }.uniq!
        expect(node_types).to eq [ 'Cucumber::Scenario', 'Cucumber::ScenarioOutline::Example' ]
      end

    end

    describe "#count" do
      it "Can pick out the passing tests from the run" do
        expect(ir.count(:passed)).to eq 7
      end

      it "Can pick out the failing tests from the run" do
        expect(ir.count(:failed)).to eq 10
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
