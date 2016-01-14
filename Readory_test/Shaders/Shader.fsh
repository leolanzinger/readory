//
//  Shader.fsh
//  Readory_test
//
//  Created by Leonardo Lanzinger on 14/01/16.
//  Copyright © 2016 Leonardo Lanzinger. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
