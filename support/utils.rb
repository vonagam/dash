require 'bundler/inline'

gemfile do

  source 'https://rubygems.org'

  gem 'plist'

  gem 'sqlite3'

  gem 'nokogiri'

  gem 'progress'

  # gem 'pry'

end

require 'fileutils'

require 'cgi'


def setup_docset

  FileUtils.cd ROOT

  require './setup.rb' unless Dir.exist? SOURCE

  FileUtils.rm_rf "#{ DOCSET }"

  FileUtils.mkdir_p "#{ DOCSET }/Contents/Resources"

  FileUtils.cp_r SOURCE, "#{ DOCSET }/Contents/Resources/Documents"

  FileUtils.cp 'icon.png', "#{ DOCSET }/icon.png"

  IO.write "#{ DOCSET }/Contents/Info.plist", Plist::Emit.dump(

    CFBundleIdentifier: ID,

    DocSetPlatformFamily: ID,

    CFBundleName: NAME,

    isDashDocset: true,

    DashDocSetFamily: 'dashtoc',

    dashIndexFilePath: 'index.html',

    isJavaScriptEnabled: true,

    DashDocSetFallbackURL: URL,

  )


  $db = SQLite3::Database.new "#{ DOCSET }/Contents/Resources/docSet.dsidx"

  $db.execute 'CREATE TABLE searchIndex ( id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT )'

  $db.execute 'CREATE UNIQUE INDEX anchor ON searchIndex ( name, type, path )'

end

def archive_docset

  FileUtils.cd ROOT

  `tar --exclude='.DS_Store' -cvzf #{ ID }.tgz #{ DOCSET }`

end

def escape_string( string )

  return CGI.escape( string ).gsub '+', '%20'

end

def insert_entry( name, type, path, hash, scope )

  path = path + '#' + hash if hash

  path = path + "<dash_entry_titleDescription=#{ escape_string scope }>" if scope

  $db.execute 'INSERT OR IGNORE INTO searchIndex ( name, type, path ) VALUES ( ?, ?, ? )', [ name, type, path ]

end

def get_entry_hash( node )

  $hash_counter ||= 0

  return node[ :id ] ||= "dashHash-#{ $hash_counter += 1 }"

end

def make_entry_anchor( node, name, type )

  node.add_previous_sibling "<a name='//apple_ref/cpp/#{ type }/#{ escape_string name }' class='dashAnchor'></a>"

end

def handle_entry( node, name, type, path, scope )

  hash = get_entry_hash node

  insert_entry name, type, path, hash, scope

  make_entry_anchor node, name, type

end

def each_html( files, &block )

  files = Dir[ files ] if files.is_a? String

  files.with_progress do | path |

    content = IO.read path

    html = Nokogiri::HTML content

    modified = block.call html, path

    IO.write path, html.to_s if modified

  end

end
