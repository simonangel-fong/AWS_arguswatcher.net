from django.urls import path
from .views import (DraftListView, BlogCreateView, BlogDetailView, BlogListView, BlogDeleteView, BlogUpdateView, post_blog,
                    blog_by_hashtag)

app_name = 'AppBlog'

urlpatterns = [
    # blog management
    path('drafts/', DraftListView.as_view(), name='draft_list'),
    path('list/', BlogListView.as_view(), name='blog_list'),
    path('new/', BlogCreateView.as_view(), name="blog_create"),
    path('detail/<int:pk>', BlogDetailView.as_view(), name="blog_detail"),
    path('edit/<int:pk>', BlogUpdateView.as_view(), name="blog_update"),
    path('delete/<int:pk>', BlogDeleteView.as_view(), name="blog_delete"),
    path('post/<int:pk>', post_blog, name="post_blog"),

    # hashtag
    path("hashtag/hashtag=<slug:slug>",
         view=blog_by_hashtag, name='blog_by_hashtag'),
]
