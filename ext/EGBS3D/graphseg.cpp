/*
 * Copyright (C) 1993-2011, by Peter I. Corke
 *
 * This file is part of The Machine Vision Toolbox for Matlab (MVTB).
 * 
 * MVTB is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * MVTB is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Leser General Public License
 * along with MVTB.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <cstdio>
#include <cstdlib>
#include "image.h"
#include "misc.h"
#include "segment-image.h"

#include    <iostream>
#include    <math.h>
#include    "mex.h"

using namespace std;

extern void _main();

/*
 * graphseg(im, K, min)
 * graphseg(im, K, min, sigma)
 * graphseg(im, pts, K, min, sigma);
 */

void mexFunction(
         int          nlhs,
         mxArray      *plhs[],
         int          nrhs,
         const mxArray *prhs[]
         )
{
    /*
     * Check for proper number of arguments
     */
    if (nlhs < 1)
        mexErrMsgTxt("igraphseg requires an output argument.");
    
    if (nrhs < 2)
        mexErrMsgTxt("igraphseg requires at least two input arguments.");
        
    int ndims = mxGetNumberOfDimensions(prhs[0]);
    if (ndims > 3)
        mexErrMsgTxt("Only 2D or 3D arrays allowed");
    
    const int *dims = mxGetDimensions(prhs[0]);
    
    int height = dims[0];
    int width = dims[1];
    
    /*  get point clouds
     */
    int ndims_d = mxGetNumberOfDimensions(prhs[1]);
    if (ndims_d > 3)
        mexErrMsgTxt("Only 2D or 3D arrays allowed");
    const int *dims_d = mxGetDimensions(prhs[1]);
    int h = dims_d[0];
    int w = dims_d[1];
    
    if ((h!=height) || (w != width))
       mexErrMsgTxt("size of img and pts should be the same");
    
    /*
     * get the scalar arguments
     */
    float K = (int) mxGetScalar(prhs[2]);
    int min_size = (int) mxGetScalar(prhs[3]);
    
    float     sigma = 0.5;
    if (nrhs == 5)
        sigma = mxGetScalar(prhs[4]);
    
    
    //printf("%d %d\n", width, height);
    
    /*
     * put the image into a format that the main cpp code can use.
     * Convert from Matlab data order and types to a float image.
     */
    image<float> *r = new image<float>(width, height);
    image<float> *g = new image<float>(width, height);
    image<float> *b = new image<float>(width, height);
     
    switch (mxGetClassID(prhs[0])) {
        case mxUINT8_CLASS: {
            unsigned char  *q, *q0 = (unsigned char *)mxGetPr(prhs[0]);
            float  *p;
            int     i;
            
            q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(r, x, y) = *q++;
                }
            }
            if (ndims < 3)
                q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(g, x, y) = *q++;
                }
            }
            if (ndims < 3)
                q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(b, x, y) = *q++;
                }
            }
            break;
        }
        case mxDOUBLE_CLASS: {
            double  *q, *q0 = mxGetPr(prhs[0]);
            float  *p;
            int     i;
            
            q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(r, x, y) = *q++;
                }
            }
            if (ndims < 3)
                q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(g, x, y) = *q++;
                }
            }
            if (ndims < 3)
                q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(b, x, y) = *q++;
                }
            }
            
            break;
        }
        default:
            mexErrMsgTxt("Only uint8 or double images allowed");
    }
    
    /* convert for point cloud again */
    image<float> *X = new image<float>(width, height);
    image<float> *Y = new image<float>(width, height);
    image<float> *Z = new image<float>(width, height);
    switch (mxGetClassID(prhs[1])) {
        case mxDOUBLE_CLASS: {
            double  *q, *q0 = mxGetPr(prhs[1]);
            float  *p;
            int     i;
            
            q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(X, x, y) = *q++;
                }
            }
            if (ndims < 3)
                q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(Y, x, y) = *q++;
                }
            }
            if (ndims < 3)
                q = q0;
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    imRef(Z, x, y) = *q++;
                }
            }
            
            break;
        }
        default:
            mexErrMsgTxt("Only double pts allowed");
    }
    
	/*
     * do the graph seg algorithm
     */
    int num_ccs; 
    
    //printf("here we go %f %d %f\n", K, min_size, sigma);
    image<int> *seg = segment_image(r, g, b, X, Y, Z, sigma, K, min_size, &num_ccs); 
    
    //printf("%d components\n", num_ccs);
    
    /*
     * make the output image and copy the data across into Matlab order
     */
    plhs[0] = mxCreateNumericMatrix(height, width, mxDOUBLE_CLASS, mxREAL);
    double  *q = mxGetPr(plhs[0]);
    int     *p;
    int     i;
    
    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            *q++ = imRef(seg, x, y);
        }
    }
    
    // optionally return the number of components
    if (nlhs == 2) {
        plhs[1] = mxCreateDoubleScalar( (double) num_ccs);
    }
    
    /* cleanup temporary storage */
    delete seg;
    delete r;
    delete g;
    delete b;
    delete X;
    delete Y;
    delete Z;
    
    return;
}
