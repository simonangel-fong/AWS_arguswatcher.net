from django.contrib import admin
from django.urls import path, include
from .views import HomeView, TestView
from django.views.generic import TemplateView

urlpatterns = [
    path('', HomeView.as_view(), name="home"),
    path('admin/', admin.site.urls),
    path("accounts/", include("AppAccount.urls")),
    path('blog/', include('AppBlog.urls')),
    path('deployer/', TemplateView.as_view(template_name='deployer.html'),
         name="deployer"),
    path('test/', TestView.as_view(), name="test"),
]
