require '../support/utils'


ID = 'haxe'

NAME = 'Haxe'

VERSION = '4.2.1'

SOURCE = "./sources/v/#{ VERSION }"

URL = "https://api.haxe.org/v/#{ VERSION }"

ROOT = __dir__

DOCSET = "#{ ID }.docset"

DOCUMENTS = "#{ DOCSET }/Contents/Resources/Documents"


setup_docset


FileUtils.cd DOCUMENTS

types = {

  'class' => 'Class',

  'final class' => 'Class',

  'abstract' => 'Class',

  'enum' => 'Enum',

  'enum abstract' => 'Enum',

  'interface' => 'Interface',

  'package' => 'Package',

  'typedef' => 'Type',

  'Constructor' => 'Constructor',

  'Variables' => 'Variable',

  'Static variables' => 'Variable',

  'Methods' => 'Method',

  'Static methods' => 'Method',

  'Fields' => 'Field',

  'Values' => 'Value',

}

each_html '**/*.html' do | html, path |

  header = html.at_css 'h1:has( small )'

  next unless header

  header_type = header.at_css( 'small' ).text

  next unless header_type && types[ header_type ]

  header_package = header.next&.text.match( /package (.+)/ )&.[]( 1 )

  header_name = header.text.delete_prefix "#{ header_type } "

  header_name = header_name.sub( /\A([^(]+)\(.+\)\z/, '\1' ) if header_type == 'abstract'

  handle_entry header, header_name, types[ header_type ], path, header_package


  field_scope = [ header_package, header_name ].compact.join '.'

  html.css( 'h3.section + .fields' ).each do | fields |

    field_type = fields.previous.text

    next unless field_type && types[ field_type ]

    fields.css( '.field' ).each do | field |

      field_name = field.at_css( '> h3:first-of-type .identifier' )&.text

      next unless field_name

      handle_entry field, field_name, types[ field_type ], path, field_scope

    end

  end


  if header_type == 'package'

    html.css( 'h1 ~ .table > tbody > tr[class] > td:first-child > a:first-of-type' ).each do | link |

      link_name = link.text

      link_type = link.parent.parent[ :class ] == 'package' ? 'Package' : 'Type'

      make_entry_anchor link, link_name, link_type

    end

  end


  true

end


archive_docset
