# -*- coding: utf-8 -*-
#
# Copyright (c) 2018 Lars Bergmann
#
# GNU GENERAL PUBLIC LICENSE
#    Version 3, 29 June 2007
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from distutils.core import setup
from Cython.Build import cythonize

setup(
    name='pygravity',
    version='0.2',
    description='Gravity simulation',
    long_description='''\
        Gravity simulation''',
    author='Lars Bergmann',
    author_email='lb@perfact.de',
    packages=[
        'pygravity', 'cygravity'
    ],
    scripts=[
        'bin/cygravity',
        'bin/pygravity',
    ],
    license='GPLv3',
    platforms=['Linux', ],
    ext_modules=cythonize(
        "cygravity/engine_bh.pyx",
        # annotate=True,
        compiler_directives={
            'boundscheck': False,
            'wraparound': False,
        },
    )
)
