from django.contrib import admin
from django.urls import path, include
from .views import HomeView, TestView


urlpatterns = [
    path('', HomeView.as_view(), name="home"),
    path('admin/', admin.site.urls),
    path("accounts/", include("AppAccount.urls")),
    path('blog/', include('AppBlog.urls')),
    path('test/', TestView.as_view(), name="test"),
]
