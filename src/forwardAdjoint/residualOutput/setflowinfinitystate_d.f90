   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.6 (r4159) - 21 Sep 2011 10:11
   !
   !  Differentiation of setflowinfinitystate in forward (tangent) mode:
   !   variations   of useful results: pinfcorr winf
   !   with respect to varying inputs: rgas uinf muinf rhoinf pinf
   !                machcoef veldirfreestream
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          setFlowInfinityState.f90                        *
   !      * Author:        Edwin van der Weide, Georgi Kalitzin            *
   !      * Starting date: 02-21-2003                                      *
   !      * Last modified: 06-12-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE SETFLOWINFINITYSTATE_D()
   USE FLOWVARREFSTATE
   USE PARAMTURB
   USE INPUTPHYSICS
   USE CONSTANTS
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * setFlowInfinityState sets the free stream state vector of      *
   !      * the flow variables. If nothing is specified for each of the    *
   !      * farfield boundaries, these values will be taken to define the  *
   !      * free stream.                                                   *
   !      *                                                                *
   !      ******************************************************************
   !
   !
   !      Local variables
   !
   INTEGER(kind=inttype) :: ierr
   REAL(kind=realtype) :: nuinf, ktmp, uinf2
   REAL(kind=realtype) :: nuinfd, ktmpd, uinf2d
   !
   !      Function definition
   !
   REAL(kind=realtype) :: SANUKNOWNEDDYRATIO
   REAL(kind=realtype) :: SANUKNOWNEDDYRATIO_D
   ! Dummy parameters
   REAL(kind=realtype) :: vinf, zinf
   REAL(kind=realtype) :: vinfd, zinfd
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Compute the velocity squared based on MachCoef;
   ! needed for the initialization of the turbulent energy,
   ! especially for moving geometries.
   uinf2d = (gammainf*((machcoefd*machcoef+machcoef*machcoefd)*pinf+&
   &    machcoef**2*pinfd)*rhoinf-machcoef**2*gammainf*pinf*rhoinfd)/rhoinf&
   &    **2
   uinf2 = machcoef*machcoef*gammainf*pinf/rhoinf
   winfd = 0.0_8
   ! Allocate the memory for wInf.
   ! Set the reference value of the flow variables, except the total
   ! energy. This will be computed at the end of this routine.
   winfd(irho) = rhoinfd
   winf(irho) = rhoinf
   winfd(ivx) = uinfd*veldirfreestream(1) + uinf*veldirfreestreamd(1)
   winf(ivx) = uinf*veldirfreestream(1)
   winfd(ivy) = uinfd*veldirfreestream(2) + uinf*veldirfreestreamd(2)
   winf(ivy) = uinf*veldirfreestream(2)
   winfd(ivz) = uinfd*veldirfreestream(3) + uinf*veldirfreestreamd(3)
   winf(ivz) = uinf*veldirfreestream(3)
   ! Set the turbulent variables if transport variables are
   ! to be solved.
   IF (equations .EQ. ransequations) THEN
   nuinfd = (muinfd*rhoinf-muinf*rhoinfd)/rhoinf**2
   nuinf = muinf/rhoinf
   SELECT CASE  (turbmodel) 
   CASE (spalartallmaras, spalartallmarasedwards) 
   winfd(itu1) = SANUKNOWNEDDYRATIO_D(eddyvisinfratio, nuinf, nuinfd&
   &        , winf(itu1))
   CASE (komegawilcox, komegamodified, mentersst) 
   !   wInf(itu1) = 1.341946*nuInf   ! eddyVis = 0.009*lamVis
   !=============================================================
   winfd(itu1) = 1.5_realType*turbintensityinf**2*uinf2d
   winf(itu1) = 1.5_realType*uinf2*turbintensityinf**2
   winfd(itu2) = (winfd(itu1)*eddyvisinfratio*nuinf-winf(itu1)*&
   &        eddyvisinfratio*nuinfd)/(eddyvisinfratio*nuinf)**2
   winf(itu2) = winf(itu1)/(eddyvisinfratio*nuinf)
   CASE (ktau) 
   !=============================================================
   winfd(itu1) = 1.5_realType*turbintensityinf**2*uinf2d
   winf(itu1) = 1.5_realType*uinf2*turbintensityinf**2
   winfd(itu2) = (eddyvisinfratio*nuinfd*winf(itu1)-eddyvisinfratio*&
   &        nuinf*winfd(itu1))/winf(itu1)**2
   winf(itu2) = eddyvisinfratio*nuinf/winf(itu1)
   CASE (v2f) 
   !=============================================================
   winfd(itu1) = 1.5_realType*turbintensityinf**2*uinf2d
   winf(itu1) = 1.5_realType*uinf2*turbintensityinf**2
   winfd(itu2) = (0.09_realType*2*winf(itu1)*winfd(itu1)*&
   &        eddyvisinfratio*nuinf-0.09_realType*winf(itu1)**2*&
   &        eddyvisinfratio*nuinfd)/(eddyvisinfratio*nuinf)**2
   winf(itu2) = 0.09_realType*winf(itu1)**2/(eddyvisinfratio*nuinf)
   winfd(itu3) = 0.666666_realType*winfd(itu1)
   winf(itu3) = 0.666666_realType*winf(itu1)
   winfd(itu4) = 0.0_8
   winf(itu4) = 0.0_realType
   END SELECT
   END IF
   ! Set the value of pInfCorr. In case a k-equation is present
   ! add 2/3 times rho*k.
   pinfcorrd = pinfd
   pinfcorr = pinf
   IF (kpresent) THEN
   pinfcorrd = pinfd + two*third*(rhoinfd*winf(itu1)+rhoinf*winfd(itu1)&
   &      )
   pinfcorr = pinf + two*third*rhoinf*winf(itu1)
   END IF
   ! Compute the free stream total energy.
   ktmp = zero
   IF (kpresent) THEN
   ktmpd = winfd(itu1)
   ktmp = winf(itu1)
   ELSE
   ktmpd = 0.0_8
   END IF
   vinf = zero
   zinf = zero
   zinfd = 0.0_8
   vinfd = 0.0_8
   CALL ETOTARRAY_D(rhoinf, rhoinfd, uinf, uinfd, vinf, vinfd, zinf, &
   &             zinfd, pinfcorr, pinfcorrd, ktmp, ktmpd, winf(irhoe), winfd&
   &             (irhoe), kpresent, 1)
   END SUBROUTINE SETFLOWINFINITYSTATE_D