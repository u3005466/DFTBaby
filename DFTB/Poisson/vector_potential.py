#!/usr/bin/env python
"""
compute vector potential A(r) generated by a distribution of magnetic dipoles M(r) 
whose x-,y- and z-components are given in three separate cube-files.

The magnetic dipole (transition) densities can be extracted from a Gaussian 09 calculation using
the 'Multiwfn' software.
"""
from DFTB.Analyse import Cube
from DFTB import AtomicData, XYZ
import numpy as np
import numpy.linalg as la

def curl_finite_differences(Mx,My,Mz, dx,dy,dz):
    """
    compute the curl of the vector field M(r) = (Mx,My,Mz)

       __   (Mx)   (dMz/dy - dMy/dz)
       \/ x (My) = (dMx/dz - dMz/dx)
            (Mz)   (dMy/dx - dMx/dy)

    using finite differences

    Parameters
    ----------
    Mx,My,Mz: 3d numpy arrays with components of vector field
    dx,dy,dz: scalars with sample distance for x-,y- and z-direction

    Returns
    -------
    rotMx,rotMy,rotMz: 3d numpy arrays components of rot(M)
    """
    dMxdx, dMxdy, dMxdz = np.gradient(Mx, dx,dy,dz)
    dMydx, dMydy, dMydz = np.gradient(My, dx,dy,dz)
    dMzdx, dMzdy, dMzdz = np.gradient(Mz, dx,dy,dz)

    rotMx = dMzdy - dMydz
    rotMy = dMxdz - dMzdx
    rotMz = dMydx - dMxdy

    return rotMx, rotMy, rotMz

def vector_potential_Poisson(atomlist, origin, axes, Mx, My, Mz,
                                    conv_eps=1.0e-10, maxiter=100000,
                                    poisson_solver="pspfft"):
    """
    compute vector potential A(r) generated by a distribution of magnetic dipoles M(r) 
    whose x-,y- and z-components are given in Mx, My and Mz. The magnetic
    dipole density is converted to a volume current density by computing its curl:

      J(r) = rot M(r)

    The vector potential is obtained by solving three Poisson equations for each component
      __2
      \/  A_i(r) = - (4 pi)/c  J_i(r)         i=x,y,z  

    where c is the speed of light (in atomic units).

    Parameters
    ----------
    atomlist
    atomlist: list of tuples (Zi,posi) with nuclear geometry
    origin: 3d vector with origin of cube file
    axes: 3 vectors spanning a voxel
    Mx,My,Mz: 
       x-,y- and z-components of magnetic dipole density for each voxel
       (Mx[i,j,k],My[i,j,k],My[i,j,k]) is the magnetic dipole at
       at position  x_ijk = origin + i*axes[0] + j*axes[1] + k*axes[2]

    Optional
    --------
    poisson_solver: choose solution method for Poisson equation, can be 'pspfft' or 'iterative'
    conv_eps: convergence threshold for iterative Poisson solver
    maxiter: maximum number of Jacobi iterations for iterative solver

    Returns
    -------
    Ax,Ay,Az: x-,y- and z-components of vector potential A(r) on the grid
    """
    if poisson_solver == "pspfft":
        try:
            from DFTB.Poisson.poisson_pspfft import poisson3d
        except ImportError as e:
            print e
            print "To be able to use the PSPFFT solver you have to "
            print "  - install the PSPFFT package from the Computer Physics Communications library"
            print "  - edit 'DFTB/Poisson/src/Makefile'"
            print "  - run 'make' inside the folder DFTB/Poisson/src"
            print ""
            exit(-1)
    else:
        from DFTB.Poisson.poisson_iterative import poisson3d
        
    assert Mx.shape == My.shape == Mz.shape, "Grids for Mx, My and Mz have to be the same"
    nx,ny,nz = Mx.shape
    # The axes have to be rectangular...
    assert abs(np.dot(axes[0], axes[1])) < 1.0e-10
    assert abs(np.dot(axes[1], axes[2])) < 1.0e-10
    #  and the points equidistant...
    dx = la.norm(axes[0])
    dy = la.norm(axes[1])
    dz = la.norm(axes[2])
    assert abs(dx - dy) < 1.0e-10
    assert abs(dx - dz) < 1.0e-10
    
    xvec = origin[0] + np.linspace(0.0, (nx-1)*dx, nx)
    yvec = origin[1] + np.linspace(0.0, (ny-1)*dy, ny)
    zvec = origin[2] + np.linspace(0.0, (nz-1)*dz, nz)
    dV = dx*dy*dz
        
    # total magnetic dipole
    magnetic_dipole = np.array([ np.sum(Mx*dV), np.sum(My*dV), np.sum(Mz*dV) ])
    print "integrated magnetic dipole (in au)    : %+7.5f  %+7.5f  %+7.5f" % tuple(magnetic_dipole)
    #                                                       __
    # compute current density J(r) as the curl of M(r), J = \/ x M
    print "compute current density J(r) = rot M(r) ..."
    Jx,Jy,Jz = curl_finite_differences(Mx,My,Mz, dx,dy,dz)
    
    # solve Poisson equation for each component
    print "solve Poisson equation for each component..."
    A = [None,None,None]
    for i,Ji in enumerate([Jx,Jy,Jz]):
        c = AtomicData.speed_of_light
        source = -4*np.pi/c * Ji
        # initial guess
        Ai_guess = 0.0*source

        A[i] = poisson3d(xvec,yvec,zvec, source, Ai_guess,
                         eps=conv_eps, maxiter=maxiter)

    return tuple(A)

if __name__ == "__main__":
    import os.path
    import sys
    from optparse import OptionParser
    
    usage = "Usage: python %s Mx.cube My.cube Mz.cube  Ax.cube Ay.cube Az.cube\n" % os.path.basename(sys.argv[0])
    usage += "  compute the vector potential A(r) generated by the magnetic dipole distribution M(r).\n"
    usage += "  The cube files Mx, My and Mz should contain the x-,y- and z-components of M(r).\n"
    usage += "  The components of the vector potential are written to the output cube files Ax,Ay and Az.\n"
    usage += "  see --help for all options.\n"
    usage += "\n"
    usage += "   Poisson Solvers\n"
    usage += "   ===============\n"
    usage += "  'iterative': The 3-dimensional Poisson equation is solved iteratively.\n"
    usage += "     The second order partial derivatives are replaced\n"
    usage += "     by finite differences and the resulting linear algebraic equations\n"
    usage += "     are solved using Jacobi iterations.\n"
    usage += "  'pspfft': faster solver based on Fourier transformation, requires the PSPFFT package\n\n"
    usage += "   Please note that the iterative Poisson solver may have difficulties\n"
    usage += "   producing solutions with the correct boundary condition A(r) -> 0 for r->inf.\n"

    usage += "\n"
    
    parser = OptionParser(usage)
    parser.add_option("--solver", dest="solver", type=str, help="Choose solution method for Poisson equation, can be 'pspfft' or 'iterative', [default: %default]", default="pspfft")
    parser.add_option("--conv_eps", dest="conv_eps", type=float, help="Convergence threshold for iterative Poisson solver [default: %default]", default=1.0e-10);
    parser.add_option("--maxiter", dest="maxiter", type=int, help="Maximum number of Jacobi iterations for iterative Poisson solver [default: %default]", default=1000000)
    
    (opts, args) = parser.parse_args()
    if len(args) < 6:
        print usage
        exit(-1)

    # input cube files
    Mx_cube_file = args[0]
    My_cube_file = args[1]
    Mz_cube_file = args[2]
    # output cube files
    Ax_cube_file = args[3]
    Ay_cube_file = args[4]
    Az_cube_file = args[5]


    # load cube files with magnetic dipole density
    print "load magnetic dipole density from cube files..."
    atomlist, origin, axes, Mx = Cube.readCube(Mx_cube_file)
    atomlist, origin, axes, My = Cube.readCube(My_cube_file)
    atomlist, origin, axes, Mz = Cube.readCube(Mz_cube_file)
    print "compute vector potential..."
    Ax,Ay,Az = vector_potential_Poisson(atomlist, origin, axes, Mx, My, Mz,
                                        poisson_solver=opts.solver,
                                        conv_eps=opts.conv_eps, maxiter=opts.maxiter)
    # save vector potential
    Cube.writeCube(Ax_cube_file, atomlist, origin, axes, Ax)
    Cube.writeCube(Ay_cube_file, atomlist, origin, axes, Ay)
    Cube.writeCube(Az_cube_file, atomlist, origin, axes, Az)
    print "x-,y- and z-components of vector potential saved to '%s', '%s' and '%s'" % (Ax_cube_file, Ay_cube_file, Az_cube_file)

