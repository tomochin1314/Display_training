//
// Fragment shader for hemispherical lighting
//
// Author: Randi Rost
//
// Copyright (C) 2005 3Dlabs, Inc.
//
// See 3Dlabs-License.txt for license information
//

varying vec4  diffuse;

void main(void)
{
    gl_FragColor = diffuse;

}
