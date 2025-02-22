!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.4
!
! Copyright (c) 2022 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
!BOP
!
! !ROUTINE: readcrd_pptEnsFcst
! \label{readcrd_pptEnsFcst}
!
! !REVISION HISTORY:
! 26 Sept 2016; KR Arsenault, Initial Code developed
!
! !INTERFACE:    
subroutine readcrd_pptEnsFcst()
! !USES:
  use ESMF
  use LIS_coreMod, only : LIS_rc, LIS_config
  use LIS_logMod,  only : LIS_logunit, LIS_verify, LIS_endrun
  use pptEnsFcst_forcingMod, only : pptensfcst_struc
!
! !DESCRIPTION:
!
!  This routine reads the options specific to the 
!  meteorological forcing data generated by LDT or 
!  by outside routines/scripts and written
!  in netCDF format.
!  
!EOP
  implicit none

  integer :: n, rc
  character(8) :: fcstinitdate
  character(4) :: chyr
  character(2) :: chmo, chda

  call ESMF_ConfigFindLabel(LIS_config,"Precipitation ensemble forecast directory:",rc=rc)
  call ESMF_ConfigGetAttribute(LIS_config,pptensfcst_struc%directory,rc=rc)

  call ESMF_ConfigFindLabel(LIS_config,"Precipitation ensemble forecast number of ensemble members:",rc=rc)
  call LIS_verify(rc, 'Precipitation ensemble forecast number of ensemble members: not defined')
  call ESMF_ConfigGetAttribute(LIS_config,pptensfcst_struc%max_ens_members,rc=rc)

! Option to select forecast year and month in LIS config file:
  call ESMF_ConfigGetAttribute(LIS_config, fcstinitdate, &
       label="Precipitation ensemble forecast initial date:",&
       default="none",rc=rc)
  call LIS_verify(rc,'Precipitation ensemble forecast initial date: not defined')
  ! If default option is set to "none":
  if( trim(fcstinitdate) == "none" ) then
     pptensfcst_struc%fcst_inityr = LIS_rc%syr
     pptensfcst_struc%fcst_initmo = LIS_rc%smo
     pptensfcst_struc%fcst_initda = LIS_rc%sda
  ! Initial forecast date set:
  else
    ! Convert readin 8-char date to integer based entries:
    chyr = fcstinitdate(1:4)
    read( chyr, '(i4)' ) pptensfcst_struc%fcst_inityr
    chmo = fcstinitdate(5:6)
    read( chmo, '(i2)' ) pptensfcst_struc%fcst_initmo
    chda = fcstinitdate(7:8)
    read( chda, '(i2)' ) pptensfcst_struc%fcst_initda
  endif

! Option to select base forecast dataset
  call ESMF_ConfigGetAttribute(LIS_config,pptensfcst_struc%fcst_type,&
       label="Name of base forecast model:",&
       default="GEOS5",rc=rc)
  call LIS_verify(rc,'Name of base forecast model: not defined')

  write(LIS_logunit,*) "[INFO] "
  write(LIS_logunit,*) "[INFO] Using the Precip Ens Fcst forcing dataset"
  write(LIS_logunit,*) "[INFO] Precipitation ensemble forecast directory: ",&
                       trim(pptensfcst_struc%directory)
  write(LIS_logunit,*) "[INFO] Precipitation ensemble forecast number of members: ",&
                       pptensfcst_struc%max_ens_members

end subroutine readcrd_pptEnsFcst

