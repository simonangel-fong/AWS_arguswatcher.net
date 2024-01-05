from django.urls import reverse_lazy
from django.contrib.auth.decorators import login_required
from django.shortcuts import render, get_object_or_404, redirect
from django.views.generic import (
    ListView, CreateView, DetailView, UpdateView, DeleteView)
from django.contrib.auth.mixins import LoginRequiredMixin

from .models import Blog, Hashtag
from .forms import BlogForm

# region public view


class DraftListView(LoginRequiredMixin, ListView):
    ''' list all drafts '''
    model = Blog
    template_name = 'AppBlog/blog_draft_list.html'
    context_object_name = 'draft_list'
    extra_context = {"heading": "Draft List",
                     "title": "Draft List"}  # context for render

    def get_queryset(self):
        # Filter drafts based on the currently logged-in user
        return Blog.objects.filter(author=self.request.user, post_at__isnull=True)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['hashtags'] = Hashtag.objects.all()
        return context


class BlogListView(ListView):
    ''' Blog list view '''
    model = Blog
    template_name = 'AppBlog/blog_list.html'
    context_object_name = 'blog_list'
    extra_context = {"heading": "Blog List",
                     "title": "Blog List"}  # context for render

    def get_queryset(self):
        # Filter the queryset to include only blog items that have been posted
        return Blog.objects.filter(post_at__isnull=False)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['hashtags'] = Hashtag.objects.all()
        return context


class BlogDetailView(DetailView):
    ''' Blog detail view '''
    model = Blog
    template_name = 'AppBlog/blog_detail.html'
    context_object_name = 'blog'
    extra_context = {"heading": "Detail",
                     "title": "Detail"}  # context for render

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['hashtags'] = Hashtag.objects.all()
        context['checked_tags'] = self.object.hashtags.filter(
            blog=self.object)  # return the related tags
        return context


# endregion

# region LoginRequired

class BlogCreateView(LoginRequiredMixin, CreateView):
    ''' Blog Create View '''
    model = Blog
    form_class = BlogForm       # The form class to instantiate.
    # The URL to redirect to when the form is successfully processed.
    success_url = reverse_lazy('AppBlog:draft_list')
    extra_context = {"heading": "New Blog",
                     "title": "New Blog"}  # context for render

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['hashtags'] = Hashtag.objects.all()     # load hashtags
        return context

    # When successfully validated
    def form_valid(self, form):
        self.object = form.save(commit=False)
        self.object.author = self.request.user
        form.save()
        return super(BlogCreateView, self).form_valid(form)


class BlogUpdateView(LoginRequiredMixin, UpdateView):
    ''' Blog update view '''
    model = Blog
    form_class = BlogForm
    context_object_name = 'blog'
    extra_context = {"heading": "Edit",
                     "title": "Edit"}  # context for render

    def get_success_url(self):
        # Redirect to the BlogDetailView with the updated blog's primary key
        return reverse_lazy('AppBlog:blog_detail', kwargs={'pk': self.object.pk})


class BlogDeleteView(LoginRequiredMixin, DeleteView):
    ''' Blog Delete View '''
    model = Blog
    success_url = reverse_lazy('AppBlog:blog_list')
    context_object_name = 'blog'
    extra_context = {"heading": "Blog Delete",
                     "title": "Blog Delete"}  # context for render

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['hashtags'] = Hashtag.objects.all()
        context['checked_tags'] = self.object.hashtags.filter(
            blog=self.object)  # return the related tags
        return context


@login_required
def post_blog(request, pk):
    ''' post a blog '''
    post = get_object_or_404(Blog, pk=pk)
    post.post_draft()
    return redirect('AppBlog:blog_detail', pk=pk)


def blog_by_hashtag(request, slug):
    ''' hashtag '''
    hashtag = get_object_or_404(Hashtag, slug=slug)
    print(hashtag)

    context = {
        "title": f"Hashtag:{hashtag.name}",
        "heading": f"Hashtag:{hashtag.name}",
        'hashtags': Hashtag.objects.all(),
        'hashtag': hashtag.name,
        # find blogs with hashtag
        "blog_list": Blog.objects.filter(hashtags=hashtag, post_at__isnull=False)
    }
    # print(context)
    template = "AppBlog/blog_list.html"
    return render(request, template, context)

# endregion
