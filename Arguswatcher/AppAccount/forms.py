from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth import get_user_model

from . import models


class UserSignupForm(UserCreationForm):
    ''' 
    This class represents a form for user to signup, inheriting from the UserCreationForm class.

    '''
    class Meta:
        model = models.UserAccount
        fields = ("username", "password1", "password2")
        # get_user_model(): return the currently active user model – the custom user model if one is specified, or User otherwise.
        model = get_user_model()
