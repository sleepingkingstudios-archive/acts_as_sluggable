# encoding: utf-8
# spec/acts_as_sluggable_spec.rb

require 'spec_helper'
require 'active_record'
require 'acts_as_sluggable'

# silence ActiveRecord schema statements
SleepingKingStudios::ActsAsSluggable::Logger = $stdout
$stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define(:version => 1) do
    create_table :sluggables do |t|
      t.column :title,      :string
      t.column :slug,       :string
      t.column :slug_lock,  :boolean
      t.column :short_name, :string
    end # create_table :sluggables
  end # Schema.define
end # function setup_db

def teardown_db
  %w(sluggables).each do |table|
    ActiveRecord::Base.connection.drop_table(table) if
      ActiveRecord::Base.connection.tables.include? table
  end # each
end # function teardown_db

class SluggableBase < ActiveRecord::Base
  self.table_name = :sluggables
end # class SluggableBase

class Sluggable < SluggableBase
  acts_as_sluggable :title
end # class Sluggable

class SluggableWithShortName < SluggableBase
  acts_as_sluggable :title, :cache_column => :short_name
end # class SluggableBase

class CustomSluggableWithValidation < SluggableBase
  acts_as_sluggable :title, :separator => '_',
    :validates => { :presence => true, :length => { :in => 4..14 } }
end # class CustomSluggable

class SluggableWithProcCallback < SluggableBase
  acts_as_sluggable :title, :callback => Proc.new { |value| value.to_s.upcase.tr(' ', '!') }
end # class SluggableWithProcCallback

class SluggableWithMethodCallback < SluggableBase
  acts_as_sluggable :title, :callback_method => :slugify
  
  def slugify(str)
    str.to_s.reverse
  end # method slugify
end # class SluggableWithMethodCallback

class SluggableWithOtherMethodCallback < SluggableBase
  acts_as_sluggable :title, :callback_method => :to_slug
  
  def to_slug
    self.title.tr("A-Za-z", "N-ZA-Mn-za-m")
  end # method to_slug
end # class SluggableWithOtherMethodCallback

class SluggableWithLock < SluggableBase
  acts_as_sluggable :title, :allow_lock => true
end # class SluggableWithLock

describe SleepingKingStudios::ActsAsSluggable do
  subject { Class.new ActiveRecord::Base }
  
  it { subject.should respond_to :acts_as_sluggable }
end # describe ActsAsSluggable

describe Sluggable do
  before :all  do teardown_db; end
  before :each do setup_db;    end
  after  :each do teardown_db; end
  
  let(:sluggable) { described_class.new }
  
  describe "validation" do
    it { sluggable.should be_valid }
  end # describe validation
  
  describe "slug= method" do
    it { expect { sluggable.slug = "bleak-house" }.to raise_error NoMethodError }
  end # describe
  
  context "saved" do
    before :each do sluggable.save end
    
    it { sluggable.slug.should == "" }
  end # context
  
  context "saved with value" do
    before :each do
      sluggable.title = "A Tale of Two Cities"
      sluggable.save
    end # before :each
    
    it { sluggable.slug.should == "a-tale-of-two-cities" }
    
    context "updated value" do
      before :each do
        sluggable.title = "The Little Prince"
        sluggable.save
      end # before :each
      
      it { sluggable.slug.should == "the-little-prince" }
    end # context updated value
  end # context saved with value
  
  context "saved with punctuation" do
    before :each do
      sluggable.title = "The Lion, The Witch, and The Wardrobe"
      sluggable.save
    end # before :each
    
    it { sluggable.slug.should == "the-lion-the-witch-and-the-wardrobe" }
  end # context saved with punctuation
  
  context "saved with accented characters" do
    before :each do
      sluggable.title = "Pokémon: The First Movie"
      sluggable.save
    end # before :each
    
    it { sluggable.slug.should == "pokemon-the-first-movie" }
  end # context saved with accented characters
end # describe ActsAsSluggable

describe SluggableWithShortName do
  before :all  do teardown_db; end
  before :each do setup_db;    end
  after  :each do teardown_db; end
  
  let(:sluggable) { described_class.new }
  
  describe "validation" do
    it { sluggable.should be_valid }
  end # describe validation
  
  describe "setting the slug manually" do
    it { expect { sluggable.short_name = "the-silmarillion" }.to raise_error NoMethodError }
  end # describe
  
  context "saved" do
    before :each do sluggable.save end
    
    it { sluggable.short_name.should == "" }
  end # context
  
  context "saved with value" do
    before :each do
      sluggable.title = "The Lord of the Rings"
      sluggable.save
    end # before :each
    
    it { sluggable.short_name.should == "the-lord-of-the-rings" }
    
    context "updated value" do
      before :each do
        sluggable.title = "The Hobbit"
        sluggable.save
      end # before :each
      
      it { sluggable.short_name.should == "the-hobbit" }
    end # context updated value
  end # context saved with value
end # describe SluggableWithShortName

describe CustomSluggableWithValidation do
  before :all  do teardown_db; end
  before :each do setup_db;    end
  after  :each do teardown_db; end
  
  let(:sluggable) { described_class.new }
  
  describe "validation" do
    context "value is nil" do
      it { sluggable.should_not be_valid }
    
      context do
        before :each do sluggable.valid? end # force validation
      
        it { sluggable.errors.messages[:slug].join.should =~ /can't be blank/i }
      end # anonymous context
    end # context value is nil
    
    context "value is too short" do
      before :each do sluggable.title = "She" end
      
      it { sluggable.should_not be_valid }
      
      context do
        before :each do sluggable.valid? end
        
        it { sluggable.errors.messages[:slug].join.should =~ /is too short/i }
      end # anonymous context
    end # context value is too short
    
    context "value is too long" do
      before :each do sluggable.title = "And Then There Were None" end
      
      it { sluggable.should_not be_valid }
      
      context do
        before :each do sluggable.valid? end
        
        it { sluggable.errors.messages[:slug].join.should =~ /is too long/i }
      end # anonymous context
    end # context value is too long
    
    context "value is just right" do
      before :each do sluggable.title = "Lolita" end
      
      it { sluggable.should be_valid }
    end # context value is just right
  end # describe validation
  
  context "saved" do
    before :each do
      sluggable.title = "The Alchemist"
      sluggable.save
    end # before :each
    
    it { sluggable.slug.should == "the_alchemist" }
  end # context saved
end # describe CustomSluggableWithValidation

describe SluggableWithProcCallback do
  before :all  do teardown_db; end
  before :each do setup_db;    end
  after  :each do teardown_db; end
  
  let(:sluggable) { described_class.new }
  
  context "saved" do
    before :each do
      sluggable.title = "Dream of the Red Chamber"
      sluggable.save
    end # before :all
    
    it { sluggable.slug.should == "DREAM!OF!THE!RED!CHAMBER" }
  end # context saved
end # describe SluggableWithProcCallback

describe SluggableWithMethodCallback do
  before :all  do teardown_db; end
  before :each do setup_db;    end
  after  :each do teardown_db; end
  
  let(:sluggable) { described_class.new }
  
  context "saved" do
    before :each do
      sluggable.title = "The Da Vinci Code"
      sluggable.save
    end # before :all
    
    it { sluggable.slug.should == "edoC icniV aD ehT" }
  end # context saved
end # describe SluggableWithProcCallback

describe SluggableWithOtherMethodCallback do
  before :all  do teardown_db; end
  before :each do setup_db;    end
  after  :each do teardown_db; end
  
  let(:sluggable) { described_class.new }
  
  context "saved" do
    before :each do
      sluggable.title = "The Catcher in the Rye"
      sluggable.save
    end # before :all
    
    it { sluggable.slug.should == "Gur Pngpure va gur Elr" }
  end # context saved
end # describe SluggableWithOtherMethodCallback

describe SluggableWithLock do
  before :all  do teardown_db; end
  before :each do setup_db;    end
  after  :each do teardown_db; end
  
  let(:sluggable) { described_class.new }
  
  describe "slug= method" do
    it { expect { sluggable.slug = "the-name-of-the-rose" }.not_to raise_error }
  end # describe slug= method
  
  context "saved" do
    before :each do
      sluggable.title = "Il Nome della Rosa"
      sluggable.save
    end # before :each
    
    it { sluggable.slug.should == "il-nome-della-rosa" }
    it { sluggable.slug_lock.should be nil }
  end # context saved
  
  context "saved with value" do
    before :each do
      sluggable.title = "Il Nome della Rosa"
      sluggable.slug = "the-name-of-the-rose"
      sluggable.save
    end # before :each
    
    it { sluggable.slug.should == "the-name-of-the-rose" }
    it { sluggable.slug_lock.should be true }
    
    describe "title= method" do
      before :each do sluggable.title = "Anne of Green Gables"; sluggable.save end
      
      it { sluggable.slug.should == "the-name-of-the-rose" }
    end # describe title= method
    
    describe "slug= method" do
      before :each do sluggable.slug = "il-nome-della-rosa" end
      
      it { sluggable.slug.should == "il-nome-della-rosa" }
    end # describe slug= method
    
    context "unlocked" do
      before :each do
        sluggable.title = "Charlotte's Web"
        sluggable.slug_lock = false
        sluggable.save
      end # before :each
      
      it { sluggable.slug.should == "charlottes-web" }
      it { sluggable.slug_lock.should be false }
    end # context unlocked
  end # context saved
end # describe SluggableWithLock
