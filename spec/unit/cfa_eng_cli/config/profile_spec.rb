# frozen_string_literal: true

require_relative '../../../../lib/cfa_eng_cli/config/profile'

RSpec.describe CfaEngCli::Config::Profile do
  subject(:profile) { described_class.new(params) }

  let(:name) { 'test-profile' }
  let(:filename) { "#{CfaEngCli::Config::Profile::PROFILE_DIRECTORY}/#{name}.yaml" }
  let(:file) { class_double(File) }
  let(:exists) { true }
  let(:params) do
    {
      name: 'test-profile',
      project: 'test-project',
      environment: 'test-environment',
      aws_profile: 'test-aws-profile',
      region: 'us-east-1'
    }
  end

  before do
    stub_const('CfaEngCli::Config::Profile::File', file)
    allow(file).to receive(:join)
      .with(CfaEngCli::Config::Profile::PROFILE_DIRECTORY, "#{name}.yaml")
      .and_return(filename)
    allow(file).to receive(:exist?).with(filename).and_return(exists)
  end

  describe '.delete' do
    before do
      allow(file).to receive(:delete).with(filename)
    end

    context 'when the profile exists' do
      it 'deletes the profile file' do
        described_class.delete(name)

        expect(file).to have_received(:delete).with(filename)
      end
    end

    context 'when the profile does not exist' do
      let(:exists) { false }

      it 'does not attempt to delete the profile file' do
        described_class.delete(name)

        expect(file).not_to have_received(:delete).with(filename)
      end
    end
  end

  describe '.list' do
    let(:files) { ['profile1.yaml', 'profile2.yaml', '.', '..'] }

    before do
      allow(Dir).to receive(:entries)
        .with(CfaEngCli::Config::Profile::PROFILE_DIRECTORY).and_return(files)
    end

    context 'when profiles exist' do
      it 'returns a list of profile names without file extensions' do
        profiles = described_class.list

        expect(profiles).to contain_exactly('profile1', 'profile2')
      end
    end

    context 'when no profiles exist' do
      let(:files) { ['.', '..'] }

      it 'returns no profiles' do
        profiles = described_class.list

        expect(profiles).to eq([])
      end
    end
  end

  describe '.load' do
    before do
      allow(YAML).to receive(:load_file).with(filename, any_args).and_return(params)
    end

    context 'when the file exists' do
      it 'loads the profile from file' do
        profile = described_class.load(name)

        expect(profile.values).to eq(params)
      end
    end

    context 'when the profile is invalid' do
      let(:params) { super().merge(project: nil) }

      it 'raises a validation error' do
        expect { described_class.load(name) }.to raise_error(
          CfaEngCli::Config::Profile::InvalidProfile,
          "Invalid profile 'test-profile': Invalid configuration"
        )
      end
    end

    context 'when the file does not exist' do
      before do
        allow(YAML).to receive(:load_file).with(filename, any_args).and_raise(Errno::ENOENT)
      end

      it 'raises InvalidProfile error when the profile file does not exist' do
        expect { described_class.load(name) }.to raise_error(
          CfaEngCli::Config::Profile::InvalidProfile,
          "Invalid profile 'test-profile': No such file or directory"
        )
      end
    end
  end

  describe '#delete' do
    before do
      allow(file).to receive(:delete).with(filename)
    end

    it 'deletes the profile file' do
      profile.delete

      expect(file).to have_received(:delete).with(filename)
    end
  end

  describe '#rename' do
    let(:new_name) { 'renamed-profile' }
    let(:new_filename) { "#{CfaEngCli::Config::Profile::PROFILE_DIRECTORY}/#{new_name}.yaml" }
    let(:new_profile) { described_class.new(params.merge(name: new_name)) }

    before do
      allow(file).to receive(:join)
        .with(CfaEngCli::Config::Profile::PROFILE_DIRECTORY, "#{new_name}.yaml")
        .and_return(new_filename)
      allow(file).to receive(:write).with(new_filename, new_profile.serialize.to_yaml)
      allow(file).to receive(:delete).with(filename)
    end

    it 'creates a new profile' do
      renamed_profile = profile.rename(new_name)

      expect(renamed_profile.name).to eq(new_name)
    end

    it 'writes the new profile' do
      profile.rename(new_name)

      expect(file).to have_received(:write).with(new_filename, new_profile.serialize.to_yaml)
    end

    it 'deletes the current profile' do
      profile.rename(new_name)

      expect(file).to have_received(:delete).with(filename)
    end
  end

  describe '#write' do
    before do
      allow(file).to receive(:write).with(filename, profile.serialize.to_yaml)
    end

    it 'writes the profile data to the correct file' do
      profile.write

      expect(file).to have_received(:write).with(filename, profile.serialize.to_yaml)
    end
  end

  describe '#serialize' do
    it 'returns a hash with string keys' do
      expect(profile.serialize.keys).to eq(params.keys.map(&:to_s))
    end

    it 'returns a hash with the correct values' do
      expect(profile.serialize.values).to eq(params.values)
    end
  end
end
