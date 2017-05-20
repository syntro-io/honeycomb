require 'spec_helper'
require 'honeycomb/parsers/android_junit'
require 'json'

describe Honeycomb::Parsers::AndroidJunit do
  let(:pass_test) { 'spec/outputs/android_junit_single_pass.out' }
  let(:failing_test) { 'spec/outputs/android_junit_single_fail.out' }
  let(:erroring_test) { 'spec/outputs/android_junit_single_error_with_retry.out'}
  let(:exception_test) { 'spec/outputs/android_junit_exception.out'}
  let(:ignored_test) { 'spec/outputs/android_junit_single_ignored.out'}

  before(:each) do
    File.delete('instruments.res') if File.exist?('instruments.res')
  end

  describe '.new' do

    it 'returns the correct results when parsing a passing test' do
      Honeycomb::Parsers::AndroidJunit.new(pass_test)
      ir = Honeycomb::IR.load('instruments.res')
      expect(ir.count(:passed)).to eq 1
      expect(ir.count(:failed)).to eq 0
      expect(ir.count(:unknown)).to eq 0
    end

    it 'returns the correct results when parsing a failing test' do
      Honeycomb::Parsers::AndroidJunit.new(failing_test)
      ir = Honeycomb::IR.load('instruments.res')
      expect(ir.count(:failed)).to eq 1
      expect(ir.count(:passed)).to eq 0
      expect(ir.count(:unknown)).to eq 0
    end

    it 'returns the correct results when parsing an erroring test' do
      Honeycomb::Parsers::AndroidJunit.new(erroring_test)
      ir = Honeycomb::IR.load('instruments.res')
      expect(ir.count(:passed)).to eq 0
      expect(ir.count(:failed)).to eq 2
      expect(ir.count(:unknown)).to eq 0
    end

    it 'returns the correct results when parsing an ignored test' do
      Honeycomb::Parsers::AndroidJunit.new(ignored_test)
      ir = Honeycomb::IR.load('instruments.res')
      expect(ir.count(:passed)).to eq 0
      expect(ir.count(:failed)).to eq 0
      expect(ir.count(:unknown)).to eq 0
    end

    it 'reports the result as failure when parsing test with exceptions' do
      Honeycomb::Parsers::AndroidJunit.new(exception_test)
      ir = Honeycomb::IR.load('instruments.res')
      expect(ir.count(:passed)).to eq 1
      expect(ir.count(:failed)).to eq 1
      expect(ir.count(:unknown)).to eq 0
      expect(ir.results.last[:type]).to eq "AndroidJUnit::Exception"
    end

  end
end
