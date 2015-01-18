require 'test_helper'

class PostViewTest < ActionView::TestCase
  setup do
    @post = Post.new
  end

  def with_concat_form_for(*args, &block)
    concat form_for(*args, &(block || proc {}))
  end

  def with_concat_form_tag(*args, &block)
    concat form_tag(*args, &(block || proc {}))
  end

  def test_form_for
    with_concat_form_for(@post, turboboost: true, html: { data: { foo: 'bar' } })
    assert_select 'form[data-remote]'
    assert_select 'form[data-turboboost]'
    assert_select "form[data-foo='bar']"
    assert_select 'form.new_post'
    assert_select 'form#new_post'
  end

  def test_form_tag
    with_concat_form_tag('/posts', turboboost: true, class: 'post-form', data: { bar: 'baz' })
    assert_select 'form[data-remote]'
    assert_select 'form.post-form'
    assert_select "form[data-bar='baz']"
    assert_select 'form[data-turboboost]'
  end
end
