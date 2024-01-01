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
