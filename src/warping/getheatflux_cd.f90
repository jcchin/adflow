!        Generated by TAPENADE     (INRIA, Tropics team)
!  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
!
SUBROUTINE GETHEATFLUX_CD(hflux, npts, sps)
  USE CONSTANTS_D
  USE BLOCKPOINTERS_D, ONLY : ndom, nbocos, bctype, bcdata
  USE SURFACEFAMILIES_D, ONLY : bcfamexchange, familyexchange, &
& zerocellval, zeronodeval
  USE UTILS_D, ONLY : setpointers
  IMPLICIT NONE
!
!      Local variables.
!
  INTEGER(kind=inttype), INTENT(IN) :: npts, sps
  REAL(kind=realtype), INTENT(OUT) :: hflux(npts)
  INTEGER(kind=inttype) :: mm, nn, i, j, ii
  INTEGER(kind=inttype) :: ibeg, iend, jbeg, jend
  TYPE(FAMILYEXCHANGE), POINTER :: exch
  EXTERNAL BCFAMEXCHANGE
  TYPE(FAMILYEXCHANGE) :: BCFAMEXCHANGE
  EXTERNAL SETPOINTERS
  EXTERNAL BCDATA
  TYPE(UNKNOWNDERIVEDTYPE) :: BCDATA
  EXTERNAL BCTYPE
  TYPE(UNKNOWNTYPE) :: BCTYPE
  EXTERNAL COMPUTEWEIGHTING
  EXTERNAL SURFACECELLCENTERTONODE
  TYPE(UNKNOWNDERIVEDTYPE) :: result1
  TYPE(UNKNOWNTYPE) :: result10
  TYPE(UNKNOWNTYPE) :: result11
  TYPE(UNKNOWNTYPE) :: result2
  TYPE(UNKNOWNTYPE) :: result12
  TYPE(UNKNOWNTYPE) :: result13
  TYPE(UNKNOWNDERIVEDTYPE) :: result20
  TYPE(UNKNOWNTYPE) :: result14
  TYPE(UNKNOWNTYPE) :: result21
  TYPE(UNKNOWNTYPE) :: nswallisothermal
  INTEGER :: nbocos
  INTEGER :: ndom
  TYPE(UNKNOWNTYPE) :: eulerwall
  TYPE(UNKNOWNTYPE) :: nswalladiabatic
  TYPE(UNKNOWNTYPE) :: zeronodeval
  TYPE(UNKNOWNTYPE) :: zerocellval
  TYPE(UNKNOWNTYPE) :: ibcgroupwalls
  REAL :: zero
  exch => BCFAMEXCHANGE(ibcgroupwalls, sps)
  DO nn=1,ndom
    CALL SETPOINTERS(nn, 1_intType, sps)
    CALL HEATFLUXES_CD()
    DO mm=1,nbocos
      result1 = BCDATA(mm)
      ibeg = result1%inbeg
      result1 = BCDATA(mm)
      iend = result1%inend
      result1 = BCDATA(mm)
      jbeg = result1%jnbeg
      result1 = BCDATA(mm)
      jend = result1%jnend
      result10 = BCTYPE(mm)
      IF (result10 .EQ. nswallisothermal) THEN
        result1 = BCDATA(mm)
        result1%cellval = BCDATA(mm)%area(:, :)
      ELSE
        result11 = BCTYPE(mm)
        result2 = BCTYPE(mm)
        IF (result11 .EQ. eulerwall .OR. result2 .EQ. nswalladiabatic) &
&       THEN
          result1 = BCDATA(mm)
          result1%cellval = zerocellval
          result1 = BCDATA(mm)
          result1%nodeval = zeronodeval
        END IF
      END IF
    END DO
  END DO
  CALL COMPUTEWEIGHTING(exch)
  DO nn=1,ndom
    CALL SETPOINTERS(nn, 1_intType, sps)
    DO mm=1,nbocos
      result12 = BCTYPE(mm)
      IF (result12 .EQ. nswallisothermal) THEN
        result1 = BCDATA(mm)
        result1%cellval = BCDATA(mm)%cellheatflux(:, :)
        result1 = BCDATA(mm)
        result1%nodeval = BCDATA(mm)%nodeheatflux(:, :)
      END IF
    END DO
  END DO
  CALL SURFACECELLCENTERTONODE(exch)
! Now extract into the flat array:
  ii = 0
  DO nn=1,ndom
    CALL SETPOINTERS(nn, 1_intType, sps)
! Loop over the number of viscous boundary subfaces of this block.
! According to preprocessing/viscSubfaceInfo, visc bocos are numbered
! before other bocos. Therefore, mm_nViscBocos == mm_nBocos
    DO mm=1,nbocos
      result13 = BCTYPE(mm)
      IF (result13 .EQ. nswallisothermal) THEN
        result1 = BCDATA(mm)
        result20 = BCDATA(mm)
        DO j=result1%jnbeg,result20%jnend
 100      result1 = BCDATA(mm)
          result20 = BCDATA(mm)
          i = result20%inend + 1
          result1 = BCDATA(mm)
          result20 = BCDATA(mm)
        END DO
      ELSE
! Simply put in zeros for the other wall BCs
        result14 = BCTYPE(mm)
        result21 = BCTYPE(mm)
        IF (result14 .EQ. nswalladiabatic .OR. result21 .EQ. eulerwall) &
&       THEN
          result1 = BCDATA(mm)
          result20 = BCDATA(mm)
          DO j=result1%jnbeg,result20%jnend
 110        result1 = BCDATA(mm)
            result20 = BCDATA(mm)
            i = result20%inend + 1
            result1 = BCDATA(mm)
            result20 = BCDATA(mm)
          END DO
        END IF
      END IF
    END DO
  END DO
END SUBROUTINE GETHEATFLUX_CD
