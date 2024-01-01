from django.urls import path
from django.contrib.auth.views import LoginView, LogoutView
from django.contrib.auth.decorators import login_required
from django.views.generic import TemplateView

# URL namespaces
app_name = "AppAccount"

urlpatterns = [
    # path("signup/", SignupView.as_view(), name="signup"),
    # a url for log in page, using login.html as template with a given context for render.
    path("login/", LoginView.as_view(
        template_name="AppAccount/login.html",
        extra_context={"title": "Login", "heading": "Login"}
    ), name="login"),

    # a url for log in page, using profile.html as template that is login required with a given context for render.
    path("profile/", login_required(TemplateView.as_view(
        template_name="AppAccount/profile.html",
        extra_context={"title": "User Profile", "heading": "User Profile"}
    )), name="profile"),

    # a url for log in page, using login.html as template with a given context for render.
    path("logout/", LogoutView.as_view(
        template_name="AppAccount/logout.html",
        extra_context={"title": "Log out", "heading": "Log out successful."}
    ), name="logout"),
]
