## ArgusWatcher - Document v0.2

[Back](/README.md)

- [ArgusWatcher - Document v0.2](#arguswatcher---document-v02)
- [Requirements](#requirements)
  - [Analysis of last version](#analysis-of-last-version)
- [Application Development](#application-development)
  - [Create app "AppAccount"](#create-app-appaccount)
  - [Create Login Page](#create-login-page)
  - [Create profile page](#create-profile-page)
  - [Create log out page](#create-log-out-page)
  - [Test locally and push](#test-locally-and-push)
- [Side Lab: using user data for EC2 provision](#side-lab-using-user-data-for-ec2-provision)
- [CI/CD](#cicd)
  - [Create Roles](#create-roles)
  - [Create an EC2 instance](#create-an-ec2-instance)
  - [Configure CodeDeploy](#configure-codedeploy)
  - [Create a CodeBuild](#create-a-codebuild)
  - [Create an application for CodeDeploy](#create-an-application-for-codedeploy)
  - [Create a deployment group for CodeDeploy](#create-a-deployment-group-for-codedeploy)
  - [Create a new CodePipeline](#create-a-new-codepipeline)
  - [Test](#test)
- [Database](#database)
- [Summary](#summary)

---

## Requirements

### Analysis of last version

| Problems                  | Solution             |
| ------------------------- | -------------------- |
| Time-consuming deployment | 1. Use data; 2. CICD |
| Use of sqlite3            | AWS RDS              |

---

- **Django Project:**

  - [x] Account Management (no signup, limited account)
    - [x] Sign-in page
    - [x] Profile page
    - [x] Sign-out page

- **AWS Cloud resources:**
  - [ ] Side Lab: using user data for EC2 provision
  - [ ] CICD
    - [ ] CodeBuild
    - [ ] CodeDeploy
    - [ ] CodePipeline
    - [ ] Test CICD
  - [ ] Store App Secret
    - [ ] SSM: parameter store for evivronment variable
    - [ ] Test
  - [ ] Database
    - [ ] Create RDS MySQL
    - [ ] Connect
    - [ ] Test RDS

---

## Application Development

### Create app "AppAccount"

- Startapp

```py
py manage.py startapp AppAccount
```

- Create model
  - leverage Django User model

```py
from django.db import models
from django.contrib.auth import models


class UserAccount(models.User, models.PermissionsMixin):
    '''
    This class represents a user account, inheriting from the User and permission models.
    custom user class
    multiple inheritance
    User class: to represent registered users of website
    Permission Class: an abstract model that has attributes and methods to cutomize a user model
    '''

    def __str__(self):
        # self.username is a attribute of the super class User.
        return self.username
```

---

### Create Login Page

- **AppAccount/urls.py**

```py
from django.urls import path
from django.contrib.auth.views import LoginView

# URL namespaces
app_name = "AppAccount"

urlpatterns = [
    path("login/", LoginView.as_view(   # using Django LoginView
        template_name="AppAccount/login.html",  # using login.html as template
        extra_context={"title": "Login", "heading": "Login"}  # define a context for render
    ), name="login"), # URL patterns name
]
```

- **AppAccount/template/AppAccount/login.html**

```html
{% extends "layout/base.html" %} {% block main %} {% load static %}
<header class="pt-5">
  <h1 class="heading text-center">{{heading}}</h1>
  <hr />
</header>

<div class="row m-3">
  <div class="col-md-8 col-sm-0">
    <img
      src="{% static 'img/home.png' %}"
      class="d-block mx-lg-auto img-fluid"
      alt="Bootstrap Themes"
      width="700"
      height="500"
      loading="lazy"
    />
  </div>
  <div class="col-md-4 col-sm-12 pt-4">
    {% if form.errors %} {% endif %} {% load django_bootstrap5 %}
    <form method="post">
      {% csrf_token %} {% bootstrap_form form %}
      <div class="row py-3">
        <button class="btn btn-primary w-100 py-2 my-1" type="submit">
          Login
        </button>
        <a
          class="btn btn-outline-secondary w-100 p-2 my-1"
          href="{% url 'home' %}"
          >Cancel</a
        >
        <input type="hidden" name="next" value="{{ next }}" />
      </div>
    </form>

    <hr />
    <p class="text-body-secondary pb-3">
      Do not have an account?
      <a class="text-body-secondary" href="#">Signup</a>
    </p>
  </div>
</div>

{% endblock %} {% block js %} {% endblock %}
```

- **Test**

![login_page](./pic/login_page.png)

---

### Create profile page

- **AppAccount/urls.py**

```py
path("profile/", login_required(  # using login_required() decorator, the current urls is required authenticated, otherwise is redirected to login page.
  TemplateView.as_view(     # using Django TemplateView for Views
    template_name="AppAccount/profile.html",  # using profile.html as template
    extra_context={"title": "User Profile", "heading": "User Profile"}  # define a given context for render.
)), name="profile"),    # url pattern name
```

- **AppAccount/template/AppAccount/profile.html**

```html
{% extends "layout/base.html" %} {% block main %}
<header class="pt-4">
  <h1 class="heading text-center">{{heading}}</h1>
  <hr />
</header>
<p><strong>Username:</strong> {{ user.username }}</p>
{% endblock %} {% block js %} {% endblock %}
```

- Craete super user for testing

```sh
py Arguswatcher/manage.py createsuperuser
# user name
# pwd
# pwd2
```

- Test login and profile

![login_profile_page](./pic/login_profile_page.png)

---

### Create log out page

- **AppAccount/urls.py**

```py
path("logout/", LogoutView.as_view(   # using Django LogoutView
        template_name="AppAccount/logout.html", # template
        extra_context={"title": "Log out", "heading": "Log out successful."}  # context for render
    ), name="logout"),  # name of url pattern
```

- Update **nav.html**

```html
<a class="dropdown-item" href="{% url 'AppAccount:logout' %}"> Logout </a>
```

- **AppAccount/template/AppAccount/logout.html**

```html
{% extends "layout/base.html" %} {% block main %}
<header class="pt-4">
  <h1 class="heading text-center">{{heading}}</h1>
  <hr />
</header>
<div class="row">
  <a href="{% url 'home' %}"> ArgusWatcher </a>
</div>
{% endblock %} {% block js %} {% endblock %}
```

- Test

![logout_page](./pic/logout_page.png)

---

### Test locally and push

- Test locally

- Collect static

  - `py Arguswatcher/manage.py collectstatic`

- Migarte

  - `py Arguswatcher/manage.py makemigrations`
  - `py Arguswatcher/manage.py migrate`

- Collect info of dependencies

  - `pip freeze > requirements.txt`

- push to Github
  - `git add -A`
  - `git log --oneline -4`
  - `git commit -m "Implement user authentication features (startapp AppAccount for login, profile, logout)"`
  - `git tag -a v0.2.0.1 -m "version 0.2 development 1"`
  - `git push`

---

## Side Lab: using user data for EC2 provision

- Create a new EC2 instance
  - define user data with bash script deploy_django_ubuntu.sh of V0.1

![use_data](./pic/use_data.png)

- Test

![use_data_test](./pic/use_data_test.png)

- Delete EC2 instance

---

## CI/CD

- `CI/CD`

  - `Continuous Integration and Continuous Deployment/Delivery`
  - the automation of the software development life cycle from dvelopment to production.
  - Steps:
    - Code
    - Build
    - Test
    - Deploy
  - Benefits:
    - Fast code deliery
    - No manaual deployment
    - Minimum errors
    - Cost reduction.
  - Common tools:
    - `GitHub Actions`:automate workflows directly from your GitHub repository.
    - `AWS CodePipeline`: automates the build, test, and deployment phases.

---

### Create Roles

- Create role that allows EC2 instance to call CodeDeploy

![cicd01](./pic/cicd01.png)

![cicd02](./pic/cicd02.png)

![cicd03](./pic/cicd03.png)

![cicd04](./pic/cicd04.png)

![cicd05](./pic/cicd05.png)

- Create role that allows CodeDeploy to call AWS services

![cicd06](./pic/cicd06.png)

![cicd07](./pic/cicd07.png)

![cicd08](./pic/cicd08.png)

![cicd09](./pic/cicd09.png)

---

### Create an EC2 instance

- OS: Ubuntu
- VPC: arguswatcherVPC
- Enable Key pair
- SG: SSH + HTTP
- Tags:
  - Name:arguswatcherServer
  - project:arguswatcher

![cicd10](./pic/cicd10.png)

- Update the IAM Role

![cicd11](./pic/cicd11.png)

- Reboot

![cicd12](./pic/cicd12.png)

---

### Configure CodeDeploy

- Access instance using SSH

```sh
sudo apt update
sudo apt install -y ruby-full     # install ruby-full package
sudo apt install -y wget          # install wget utility
```

- Install CodeDeploy files on EC2

  - Many of the files CodeDeploy relies on are stored in publicly available, AWS region-specific Amazon S3 buckets.
    - These files include installation files for the CodeDeploy agent, templates, and sample application files. We call this collection of files the CodeDeploy Resource Kit.
  - rel:

    - https://docs.aws.amazon.com/codedeploy/latest/userguide/resource-kit.html

  - for us-east-1
    - https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install

```sh
# download codedeploy on the EC2
wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
# change permission of the install file
sudo chmod +x ./install
# install and log the output to the tmp/logfile.file
sudo ./install auto  > /tmp/logfile
# check whether the CodeDeploy is running
sudo service codedeploy-agent status
```

![cicd13](./pic/cicd13.png)

![cicd14](./pic/cicd14.png)

---

### Create a CodeBuild

![codebuild01](./pic/codebuild01.png)

- Choose Github as source

![codebuild02](./pic/codebuild02.png)

![codebuild03](./pic/codebuild03.png)

![codebuild04](./pic/codebuild04.png)

![codebuild05](./pic/codebuild05.png)

![codebuild06](./pic/codebuild06.png)

---

### Create an application for CodeDeploy

![codedeloyapp01](./pic/codedeloyapp01.png)

### Create a deployment group for CodeDeploy

![codedeloydpgroup01](./pic/codedeloydpgroup01.png)

![codedeloydpgroup02](./pic/codedeloydpgroup02.png)

- Select the correct tag held by the target EC2 instance.

![codedeloydpgroup03](./pic/codedeloydpgroup03.png)

![codedeloydpgroup04](./pic/codedeloydpgroup04.png)

- At this stage disable load balancer.
  - It can enbale later when CICD work well.

![codedeloydpgroup05](./pic/codedeloydpgroup05.png)

---

### Create a new CodePipeline

![codepipeline01](./pic/codepipeline01.png)

![codepipeline02](./pic/codepipeline02.png)

![codepipeline03](./pic/codepipeline03.png)

![codepipeline04](./pic/codepipeline04.png)

![codepipeline05](./pic/codepipeline05.png)

![codepipeline06](./pic/codepipeline06.png)

---

### Test

- Commit and push

---

## Database

---

## Summary

---

[TOP](#arguswatcher---document-v02)
