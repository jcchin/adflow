   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.3 (r3163) - 09/25/2009 09:03
   !
   !  Differentiation of computeforceandmomentadj in reverse (adjoint) mode:
   !   gradient, with respect to input variables: pointrefadj moment
   !                wblock lift cforce alphaadj pts betaadj drag force
   !                cd cl machcoefadj cmoment
   !   of linear combination of output variables: moment lift cforce
   !                drag force cd cl cmoment
   SUBROUTINE COMPUTEFORCEANDMOMENTADJ_B(force, forceb, cforce, cforceb, &
   &  lift, liftb, drag, dragb, cl, clb, cd, cdb, moment, momentb, cmoment, &
   &  cmomentb, alphaadj, alphaadjb, betaadj, betaadjb, liftindex, &
   &  machcoefadj, machcoefadjb, pointrefadj, pointrefadjb, pts, ptsb, npts&
   &  , wblock, wblockb, righthandedadj, faceid, ibeg, iend, jbeg, jend, &
   &  ii_start)
   USE BLOCKPOINTERS
   USE BCTYPES
   USE INPUTPHYSICS
   USE INPUTDISCRETIZATION
   USE FLOWVARREFSTATE
   IMPLICIT NONE
   !     ******************************************************************
   !     *                                                                *
   !     * Compute the sum of the forces and moments on all blocks on     *
   !     * this processor. This function can be AD'd                      *
   !     *                                                                *
   !     ******************************************************************
   !
   ! equations
   ! nw
   ! spaceDiscr, useCompactDiss
   !imin,imax,jmin,jmax,kmin,kmax
   ! Subroutine Arguments
   ! Output
   REAL(kind=realtype) :: force(3), cforce(3)
   REAL(kind=realtype) :: forceb(3), cforceb(3)
   REAL(kind=realtype) :: lift, drag, cl, cd
   REAL(kind=realtype) :: liftb, dragb, clb, cdb
   REAL(kind=realtype) :: moment(3), cmoment(3)
   REAL(kind=realtype) :: momentb(3), cmomentb(3)
   ! Input
   REAL(kind=realtype), INTENT(IN) :: alphaadj, betaadj
   REAL(kind=realtype) :: alphaadjb, betaadjb
   INTEGER(kind=inttype), INTENT(IN) :: liftindex
   REAL(kind=realtype), INTENT(IN) :: machcoefadj
   REAL(kind=realtype) :: machcoefadjb
   REAL(kind=realtype), INTENT(IN) :: pointrefadj(3)
   REAL(kind=realtype) :: pointrefadjb(3)
   INTEGER(kind=inttype), INTENT(IN) :: npts
   REAL(kind=realtype), INTENT(IN) :: pts(3, npts)
   REAL(kind=realtype) :: ptsb(3, npts)
   REAL(kind=realtype), INTENT(IN) :: wblock(0:ib, 0:jb, 0:kb, nw)
   REAL(kind=realtype) :: wblockb(0:ib, 0:jb, 0:kb, nw)
   LOGICAL, INTENT(IN) :: righthandedadj
   INTEGER(kind=inttype), INTENT(IN) :: faceid
   INTEGER(kind=inttype), INTENT(IN) :: ibeg, iend, jbeg, jend, ii_start
   ! Local Variables
   INTEGER(kind=inttype) :: ii
   REAL(kind=realtype) :: addforce(3), addmoment(3), refpoint(3)
   REAL(kind=realtype) :: addforceb(3), addmomentb(3)
   REAL(kind=realtype) :: liftdir(3), dragdir(3), freestreamdir(3)
   REAL(kind=realtype) :: liftdirb(3), dragdirb(3)
   REAL(kind=realtype) :: grid_pts(3, 3, 3), wadj(2, 2, 2, nw)
   REAL(kind=realtype) :: grid_ptsb(3, 3, 3), wadjb(2, 2, 2, nw)
   INTEGER(kind=inttype) :: istride, jstride, i, j
   INTEGER(kind=inttype) :: iii, jjj, kkk
   INTEGER(kind=inttype) :: lower_left, lower_right, upper_left, &
   &  upper_right
   REAL(kind=realtype) :: fact
   REAL(kind=realtype) :: factb
   REAL(kind=realtype) :: veldirfreestreamadj(3)
   INTEGER :: branch
   REAL(kind=realtype) :: temp0
   REAL(kind=realtype) :: temp
   ! Only need to zero force and moment -> these are summed again
   force = 0.0
   moment = 0.0
   istride = iend - ibeg + 1
   ii = ii_start
   DO j=jbeg,jend
   DO i=ibeg,iend
   CALL PUSHREAL8ARRAY(grid_pts, realtype*3**3/8)
   grid_pts(:, :, :) = 0.0
   CALL PUSHREAL8ARRAY(wadj, realtype*2**3*nw/8)
   wadj(:, :, :, :) = 0.0
   DO iii=1,2
   DO jjj=1,2
   CALL PUSHINTEGER4ARRAY(lower_left, inttype/4)
   lower_left = ii + iii + (jjj-1)*istride - istride - 1
   CALL PUSHINTEGER4ARRAY(lower_right, inttype/4)
   lower_right = ii + iii + (jjj-1)*istride - istride
   CALL PUSHINTEGER4ARRAY(upper_left, inttype/4)
   upper_left = ii + iii + jjj*istride - istride - 1
   CALL PUSHINTEGER4ARRAY(upper_right, inttype/4)
   upper_right = ii + iii + jjj*istride - istride
   IF (lower_left .GT. 0 .AND. lower_left .LE. npts) THEN
   grid_pts(:, iii, jjj) = pts(:, lower_left)
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   IF (lower_right .GT. 0 .AND. lower_right .LE. npts) THEN
   grid_pts(:, iii+1, jjj) = pts(:, lower_right)
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   IF (upper_left .GT. 0 .AND. upper_left .LE. npts) THEN
   grid_pts(:, iii, jjj+1) = pts(:, upper_left)
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   IF (upper_right .GT. 0 .AND. upper_right .LE. npts) THEN
   grid_pts(:, iii+1, jjj+1) = pts(:, upper_right)
   CALL PUSHINTEGER4(2)
   ELSE
   CALL PUSHINTEGER4(1)
   END IF
   END DO
   END DO
   !Copy over the states
   SELECT CASE  (faceid) 
   CASE (imin) 
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = -1_realType
   DO kkk=1,2
   wadj(kkk, 1, 1, :) = wblock(kkk+1, i, j, :)
   wadj(kkk, 2, 1, :) = wblock(kkk+1, i+1, j, :)
   wadj(kkk, 1, 2, :) = wblock(kkk+1, i, j+1, :)
   wadj(kkk, 2, 2, :) = wblock(kkk+1, i+1, j+1, :)
   END DO
   CALL PUSHINTEGER4(1)
   CASE (imax) 
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = 1_realType
   DO kkk=1,2
   wadj(kkk, 1, 1, :) = wblock(ib-kkk-1, i, j, :)
   wadj(kkk, 2, 1, :) = wblock(ib-kkk-1, i+1, j, :)
   wadj(kkk, 1, 2, :) = wblock(ib-kkk-1, i, j+1, :)
   wadj(kkk, 2, 2, :) = wblock(ib-kkk-1, i+1, j+1, :)
   END DO
   CALL PUSHINTEGER4(2)
   CASE (jmin) 
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = 1_realType
   DO kkk=1,2
   wadj(kkk, 1, 1, :) = wblock(i, kkk+1, j, :)
   wadj(kkk, 2, 1, :) = wblock(i+1, kkk+1, j, :)
   wadj(kkk, 1, 2, :) = wblock(i, kkk+1, j+1, :)
   wadj(kkk, 2, 2, :) = wblock(i+1, kkk+1, j+1, :)
   END DO
   CALL PUSHINTEGER4(3)
   CASE (jmax) 
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = -1_realType
   DO kkk=1,2
   wadj(kkk, 1, 1, :) = wblock(i, jb-kkk-1, j, :)
   wadj(kkk, 2, 1, :) = wblock(i+1, jb-kkk-1, j, :)
   wadj(kkk, 1, 2, :) = wblock(i, jb-kkk-1, j+1, :)
   wadj(kkk, 2, 2, :) = wblock(i+1, jb-kkk-1, j+1, :)
   END DO
   CALL PUSHINTEGER4(4)
   CASE (kmin) 
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = -1_realType
   DO kkk=1,2
   wadj(kkk, 1, 1, :) = wblock(i, j, kkk+1, :)
   wadj(kkk, 2, 1, :) = wblock(i+1, j, kkk+1, :)
   wadj(kkk, 1, 2, :) = wblock(i, j+1, kkk+1, :)
   wadj(kkk, 2, 2, :) = wblock(i+1, j+1, kkk+1, :)
   END DO
   CALL PUSHINTEGER4(5)
   CASE (kmax) 
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = 1_realType
   DO kkk=1,2
   wadj(kkk, 1, 1, :) = wblock(i, j, kb-kkk-1, :)
   wadj(kkk, 2, 1, :) = wblock(i+1, j, kb-kkk-1, :)
   wadj(kkk, 1, 2, :) = wblock(i, j+1, kb-kkk-1, :)
   wadj(kkk, 2, 2, :) = wblock(i+1, j+1, kb-kkk-1, :)
   END DO
   CALL PUSHINTEGER4(6)
   CASE DEFAULT
   CALL PUSHINTEGER4(0)
   END SELECT
   CALL COMPUTEFORCESADJ(addforce, addmoment, grid_pts, wadj, &
   &                         pointrefadj, fact, ibeg, iend, jbeg, jend, i, j&
   &                         , righthandedadj)
   ii = ii + 1
   force = force + addforce
   moment = moment + addmoment
   END DO
   END DO
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   ! Now we know the sum of the force and moment contribution from this block
   ! First get cForce -> Coefficient of FOrce
   fact = two/(gammainf*pinf*pref*machcoefadj*machcoefadj*surfaceref*lref&
   &    *lref)
   ! To get Lift,Drag,Cl and Cd get lift and drag directions
   CALL ADJUSTINFLOWANGLEFORCESADJ(alphaadj, betaadj, &
   &                               veldirfreestreamadj, liftdir, dragdir, &
   &                               liftindex)
   ! Take Dot Products ... this won't AD properly so we will write explictly
   !Lift = dot_product(Force,liftDir)
   !Drag = dot_product(Force,dragDir)
   lift = force(1)*liftdir(1) + force(2)*liftdir(2) + force(3)*liftdir(3)
   drag = force(1)*dragdir(1) + force(2)*dragdir(2) + force(3)*dragdir(3)
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   ! Update fact for moment normalization
   fact = fact/(lengthref*lref)
   momentb = momentb + fact*cmomentb
   factb = SUM(moment*cmomentb)
   CALL POPREAL8ARRAY(fact, realtype/8)
   factb = drag*cdb + SUM(force*cforceb) + lift*clb + factb/(lengthref*&
   &    lref)
   dragb = dragb + fact*cdb
   liftb = liftb + fact*clb
   dragdirb = 0.0
   forceb(1) = forceb(1) + dragdir(1)*dragb
   dragdirb(1) = force(1)*dragb
   forceb(2) = forceb(2) + dragdir(2)*dragb
   dragdirb(2) = force(2)*dragb
   forceb(3) = forceb(3) + dragdir(3)*dragb
   dragdirb(3) = force(3)*dragb
   liftdirb = 0.0
   forceb(1) = forceb(1) + liftdir(1)*liftb
   liftdirb(1) = force(1)*liftb
   forceb(2) = forceb(2) + liftdir(2)*liftb
   liftdirb(2) = force(2)*liftb
   forceb(3) = forceb(3) + liftdir(3)*liftb
   liftdirb(3) = force(3)*liftb
   CALL ADJUSTINFLOWANGLEFORCESADJ_B(alphaadj, alphaadjb, betaadj, &
   &                              betaadjb, veldirfreestreamadj, liftdir, &
   &                              liftdirb, dragdir, dragdirb, liftindex)
   forceb = forceb + fact*cforceb
   CALL POPREAL8ARRAY(fact, realtype/8)
   temp0 = gammainf*pinf*lref**2*pref*surfaceref
   temp = temp0*machcoefadj**2
   machcoefadjb = -(two*temp0*2*machcoefadj*factb/temp**2)
   pointrefadjb = 0.0
   wblockb = 0.0
   ptsb = 0.0
   addforceb = 0.0
   DO j=jend,jbeg,-1
   DO i=iend,ibeg,-1
   addmomentb = 0.0
   addmomentb = momentb
   addforceb = addforceb + forceb
   CALL COMPUTEFORCESADJ_B(addforce, addforceb, addmoment, addmomentb&
   &                        , grid_pts, grid_ptsb, wadj, wadjb, pointrefadj&
   &                        , pointrefadjb, fact, ibeg, iend, jbeg, jend, i&
   &                        , j, righthandedadj)
   addforceb = 0.0
   CALL POPINTEGER4(branch)
   IF (branch .LT. 4) THEN
   IF (branch .LT. 2) THEN
   IF (.NOT.branch .LT. 1) THEN
   DO kkk=2,1,-1
   wblockb(kkk+1, i+1, j+1, :) = wblockb(kkk+1, i+1, j+1, :) &
   &                + wadjb(kkk, 2, 2, :)
   wadjb(kkk, 2, 2, :) = 0.0
   wblockb(kkk+1, i, j+1, :) = wblockb(kkk+1, i, j+1, :) + &
   &                wadjb(kkk, 1, 2, :)
   wadjb(kkk, 1, 2, :) = 0.0
   wblockb(kkk+1, i+1, j, :) = wblockb(kkk+1, i+1, j, :) + &
   &                wadjb(kkk, 2, 1, :)
   wadjb(kkk, 2, 1, :) = 0.0
   wblockb(kkk+1, i, j, :) = wblockb(kkk+1, i, j, :) + wadjb(&
   &                kkk, 1, 1, :)
   wadjb(kkk, 1, 1, :) = 0.0
   END DO
   CALL POPREAL8ARRAY(fact, realtype/8)
   END IF
   ELSE IF (branch .LT. 3) THEN
   DO kkk=2,1,-1
   wblockb(ib-kkk-1, i+1, j+1, :) = wblockb(ib-kkk-1, i+1, j+1&
   &              , :) + wadjb(kkk, 2, 2, :)
   wadjb(kkk, 2, 2, :) = 0.0
   wblockb(ib-kkk-1, i, j+1, :) = wblockb(ib-kkk-1, i, j+1, :) &
   &              + wadjb(kkk, 1, 2, :)
   wadjb(kkk, 1, 2, :) = 0.0
   wblockb(ib-kkk-1, i+1, j, :) = wblockb(ib-kkk-1, i+1, j, :) &
   &              + wadjb(kkk, 2, 1, :)
   wadjb(kkk, 2, 1, :) = 0.0
   wblockb(ib-kkk-1, i, j, :) = wblockb(ib-kkk-1, i, j, :) + &
   &              wadjb(kkk, 1, 1, :)
   wadjb(kkk, 1, 1, :) = 0.0
   END DO
   CALL POPREAL8ARRAY(fact, realtype/8)
   ELSE
   DO kkk=2,1,-1
   wblockb(i+1, kkk+1, j+1, :) = wblockb(i+1, kkk+1, j+1, :) + &
   &              wadjb(kkk, 2, 2, :)
   wadjb(kkk, 2, 2, :) = 0.0
   wblockb(i, kkk+1, j+1, :) = wblockb(i, kkk+1, j+1, :) + &
   &              wadjb(kkk, 1, 2, :)
   wadjb(kkk, 1, 2, :) = 0.0
   wblockb(i+1, kkk+1, j, :) = wblockb(i+1, kkk+1, j, :) + &
   &              wadjb(kkk, 2, 1, :)
   wadjb(kkk, 2, 1, :) = 0.0
   wblockb(i, kkk+1, j, :) = wblockb(i, kkk+1, j, :) + wadjb(&
   &              kkk, 1, 1, :)
   wadjb(kkk, 1, 1, :) = 0.0
   END DO
   CALL POPREAL8ARRAY(fact, realtype/8)
   END IF
   ELSE IF (branch .LT. 6) THEN
   IF (branch .LT. 5) THEN
   DO kkk=2,1,-1
   wblockb(i+1, jb-kkk-1, j+1, :) = wblockb(i+1, jb-kkk-1, j+1&
   &              , :) + wadjb(kkk, 2, 2, :)
   wadjb(kkk, 2, 2, :) = 0.0
   wblockb(i, jb-kkk-1, j+1, :) = wblockb(i, jb-kkk-1, j+1, :) &
   &              + wadjb(kkk, 1, 2, :)
   wadjb(kkk, 1, 2, :) = 0.0
   wblockb(i+1, jb-kkk-1, j, :) = wblockb(i+1, jb-kkk-1, j, :) &
   &              + wadjb(kkk, 2, 1, :)
   wadjb(kkk, 2, 1, :) = 0.0
   wblockb(i, jb-kkk-1, j, :) = wblockb(i, jb-kkk-1, j, :) + &
   &              wadjb(kkk, 1, 1, :)
   wadjb(kkk, 1, 1, :) = 0.0
   END DO
   CALL POPREAL8ARRAY(fact, realtype/8)
   ELSE
   DO kkk=2,1,-1
   wblockb(i+1, j+1, kkk+1, :) = wblockb(i+1, j+1, kkk+1, :) + &
   &              wadjb(kkk, 2, 2, :)
   wadjb(kkk, 2, 2, :) = 0.0
   wblockb(i, j+1, kkk+1, :) = wblockb(i, j+1, kkk+1, :) + &
   &              wadjb(kkk, 1, 2, :)
   wadjb(kkk, 1, 2, :) = 0.0
   wblockb(i+1, j, kkk+1, :) = wblockb(i+1, j, kkk+1, :) + &
   &              wadjb(kkk, 2, 1, :)
   wadjb(kkk, 2, 1, :) = 0.0
   wblockb(i, j, kkk+1, :) = wblockb(i, j, kkk+1, :) + wadjb(&
   &              kkk, 1, 1, :)
   wadjb(kkk, 1, 1, :) = 0.0
   END DO
   CALL POPREAL8ARRAY(fact, realtype/8)
   END IF
   ELSE
   DO kkk=2,1,-1
   wblockb(i+1, j+1, kb-kkk-1, :) = wblockb(i+1, j+1, kb-kkk-1, :&
   &            ) + wadjb(kkk, 2, 2, :)
   wadjb(kkk, 2, 2, :) = 0.0
   wblockb(i, j+1, kb-kkk-1, :) = wblockb(i, j+1, kb-kkk-1, :) + &
   &            wadjb(kkk, 1, 2, :)
   wadjb(kkk, 1, 2, :) = 0.0
   wblockb(i+1, j, kb-kkk-1, :) = wblockb(i+1, j, kb-kkk-1, :) + &
   &            wadjb(kkk, 2, 1, :)
   wadjb(kkk, 2, 1, :) = 0.0
   wblockb(i, j, kb-kkk-1, :) = wblockb(i, j, kb-kkk-1, :) + &
   &            wadjb(kkk, 1, 1, :)
   wadjb(kkk, 1, 1, :) = 0.0
   END DO
   CALL POPREAL8ARRAY(fact, realtype/8)
   END IF
   DO iii=2,1,-1
   DO jjj=2,1,-1
   CALL POPINTEGER4(branch)
   IF (.NOT.branch .LT. 2) THEN
   ptsb(:, upper_right) = ptsb(:, upper_right) + grid_ptsb(:, &
   &              iii+1, jjj+1)
   grid_ptsb(:, iii+1, jjj+1) = 0.0
   END IF
   CALL POPINTEGER4(branch)
   IF (.NOT.branch .LT. 1) THEN
   ptsb(:, upper_left) = ptsb(:, upper_left) + grid_ptsb(:, iii&
   &              , jjj+1)
   grid_ptsb(:, iii, jjj+1) = 0.0
   END IF
   CALL POPINTEGER4(branch)
   IF (.NOT.branch .LT. 1) THEN
   ptsb(:, lower_right) = ptsb(:, lower_right) + grid_ptsb(:, &
   &              iii+1, jjj)
   grid_ptsb(:, iii+1, jjj) = 0.0
   END IF
   CALL POPINTEGER4(branch)
   IF (.NOT.branch .LT. 1) THEN
   ptsb(:, lower_left) = ptsb(:, lower_left) + grid_ptsb(:, iii&
   &              , jjj)
   grid_ptsb(:, iii, jjj) = 0.0
   END IF
   CALL POPINTEGER4ARRAY(upper_right, inttype/4)
   CALL POPINTEGER4ARRAY(upper_left, inttype/4)
   CALL POPINTEGER4ARRAY(lower_right, inttype/4)
   CALL POPINTEGER4ARRAY(lower_left, inttype/4)
   END DO
   END DO
   CALL POPREAL8ARRAY(wadj, realtype*2**3*nw/8)
   CALL POPREAL8ARRAY(grid_pts, realtype*3**3/8)
   END DO
   END DO
   momentb = 0.0
   liftb = 0.0
   cforceb = 0.0
   dragb = 0.0
   forceb = 0.0
   cdb = 0.0
   clb = 0.0
   cmomentb = 0.0
   END SUBROUTINE COMPUTEFORCEANDMOMENTADJ_B