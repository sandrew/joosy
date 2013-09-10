describe "Joosy.Helpers.View", ->

  # Shortcut
  h = Joosy.Helpers.Application

  it "renders tag with string content", ->
    tag = h.contentTag 'div', 'content', {id: 'id'}
    expect(tag).toBeTag 'div', 'content', id: 'id'

  it "renders tag with lambda content", ->
    tag = h.contentTag 'div', {id: 'id'}, ->
      h.contentTag 'div', 'content', {id: 'id2'}

    expect(tag.toLowerCase()).toEqualHTML '<div id="id"><div id="id2">content</div></div>'
