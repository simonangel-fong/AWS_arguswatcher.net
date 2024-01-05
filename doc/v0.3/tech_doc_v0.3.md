## ArgusWatcher - Document v0.3

[Back](/README.md)

- [ArgusWatcher - Document v0.3](#arguswatcher---document-v03)
- [Requirements](#requirements)
  - [Current version](#current-version)
- [Application Development - Blog management](#application-development---blog-management)
  - [Create app `AppBlog`](#create-app-appblog)
  - [Blog management](#blog-management)
  - [Hashtag](#hashtag)
  - [Update profile page](#update-profile-page)
  - [Test, Commit, and Push](#test-commit-and-push)
- [AWS Architect](#aws-architect)
- [Summary](#summary)
  - [Challenge and Lesson](#challenge-and-lesson)
  - [Troubleshooting](#troubleshooting)

---

## Requirements

---

### Current version

- **Django Project:**

  - [x] Blog Management
    - [x] List
    - [x] Create
    - [x] Update
    - [x] Delete
    - [x] Publish
    - [x] HashTag
    - [x] filter by hashtag
    - [x] attach hashtag
  - [x] Design Home Page

- **AWS Cloud resources:**
  - [ ] Auto Scalling Group
  - [ ] Multi-AZ
  - [ ] RDS replica

---

## Application Development - Blog management

- Blog lifecycle:

  - 1. CRUD draft
  - 2. post a blog(draft -> blog)
  - 2. RUD blog

- only login user can crud a draft.
- only login user can ud a blog.
- Anonymous user can read a blog.
- No comment function for the current version.
- Hashtag managed by admin

---

### Create app `AppBlog`

- Startapp

```sh
py manage.py startapp AppBlog
```

- Create Blog model

  - Each blog is related to an authenticated user.
  - use foreign key "auth.User" to reference the user model.

```py
from django.db import models
from django.urls import reverse
from django.utils import timezone
from django.utils.text import slugify


class Blog(models.Model):
    ''' Table of blog '''

    # author, refer to auth User, Only the registered user can post.
    author = models.ForeignKey("auth.User",
                               on_delete=models.CASCADE)
    # # the title of current post, allow only 64 characters
    title = models.CharField(max_length=64)
    # the content of current post, Can be blank or null
    content = models.TextField(blank=True, null=True)
    # created time, automatically set the field to now when the object is first created.
    created_at = models.DateTimeField(auto_now_add=True)
    # last updated time, automatically set the field to now every time the object is saved.
    updated_at = models.DateTimeField(auto_now=True)
    # the date when current post is set to be published,  It can be blan or null when the post is not set published.
    post_at = models.DateTimeField(blank=True, null=True)
    hashtags = models.ManyToManyField('Hashtag')

    # model metadata
    class Meta:
        # OrderBy created_date in descending order.
        ordering = ["-created_at"]
        # set index for post table
        indexes = [
            models.Index(fields=["author",]),
            models.Index(fields=["title",]),
            models.Index(fields=["created_at",]),
            models.Index(fields=["updated_at",]),
        ]

    def __str__(self):
        ''' str() method of current post'''
        return f'{self.title} - {self.author}'

    def get_absolute_url(self):
        ''' the url for current blog '''
        # using reverse to transform URLConf name into a url of current blog.
        # passing the pk of current blog an argument.
        return reverse("blog_detail", kwargs={"pk": self.pk})

    def post_draft(self):
        ''' post a draft into a blog '''
        if not self.post_at:
            self.post_at = timezone.now()
            self.save()
```

---

- Register Blog model in the admin

```py
# AppBlog/admin.py
from django.contrib import admin
from .models import Blog

admin.site.register(Blog)
```

---

- Migrate

  - `py manage.py makemigrations`
  - `py manage.py migrate`

---

- log in admin page to create a new blog for testing.

![blog01](./pic/blog01.png)

![blog02](./pic/blog02.png)

---

### Blog management

- Views:list

```py
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
```

- Urls

```py
from django.urls import path
from .views import (DraftListView)

app_name = 'AppBlog'

urlpatterns = [
    # blog management
    path('drafts/', DraftListView.as_view(), name='draft_list'),
]
```

- Project urls

```py
    path('blog/', include('AppBlog.urls')),
```

- template
  - create a AppBlog_base.html template for AppBlog extending from the base.html

```html
{% extends "layout/base.html" %} {% block main%}
<header class="pt-4">{% include "AppBlog/layout/header.html" %}</header>
<hr />
<div class="container-fluid">
  <div class="row">
    <div class="col-lg-3 col-md-12">
      {% include "AppBlog/layout/sidebar.html" %}
    </div>
    <div class="col-lg-9 col-md-12">{% block blog_page %}{% endblock %}</div>
  </div>
</div>
{% endblock %}
```

- Each page of AppBlog extends from the AppBlog_base.html.

```html
{% extends "AppBlog/layout/AppBlog_base.html" %} {% block blog_page %}
<div>
  {% for blog in draft_list %}
  <article class="py-4">
    <h3 class="link-body-emphasis">
      <a href="{% url 'AppBlog:blog_detail' pk=blog.pk %}"> {{blog.title}} </a>
    </h3>
    <p class="fw-normal text-body-secondary">
      <span> {{blog.created_at|date:'F-d, Y G:i:s'}} by {{blog.author}} </span>
    </p>

    <p>{{blog.content|safe|linebreaks|truncatewords_html:48}}</p>
    <hr />
  </article>

  {% empty %}
  <p class="fs-4">No draft.</p>
  {% endfor %}
</div>
{% endblock %} {% block js %}
<script>
  tinymce.init({
    selector: ".editor",
  });
</script>
{% endblock %}
```

- Test

![blog03](./pic/blog03.png)

---

- Same approach serves create, detail, update, delete pages.

---

### Hashtag

- model
  - Many to many relationship
  - A hashtag can be related to multiple blogs.
  - A blog can be related to multiple hashtags.
  - rel:
    - https://docs.djangoproject.com/en/5.0/topics/db/examples/many_to_many/

```py
class Blog(models.Model):
    ''' Table of blog '''
    hashtags = models.ManyToManyField('Hashtag')

class Hashtag(models.Model):
    # name of hashtag
    name = models.CharField(
        max_length=32,  # less than 32 chars
        unique=True     # must be unique
    )
    slug = models.SlugField(
        unique=True,        # must be unique
        allow_unicode=True,  # accepts Unicode letters
    )

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def get_absolute_url(self):
        return reverse("AppBlog:hashtag_detail", kwargs={"slug": self.slug})

    class Meta:
        ordering = ["name"]     # default ordered by name
```

---

- Update blog pages to for hashtag pages

---

### Update profile page

- update profile page

![hashtag04](./pic/blog04.png)

---

### Test, Commit, and Push

---

## AWS Architect

![arguswatcher_v0.3](./diagram/arguswatcher_v0.3.png)

- Muti-AZ, three tiers website application
  - AZ: us-east-1a, us-east-1b
  - VPC: 1
  - pulic subnets: 2, multi-az
  - private subnets: 2, multi-az

---

## Summary

### Challenge and Lesson

---

### Troubleshooting

---

[TOP](#arguswatcher---document-v03)
