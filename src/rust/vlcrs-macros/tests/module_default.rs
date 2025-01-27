//
// Copyright (C) 2024      Alexandre Janniaux <ajanni@videolabs.io>
//

#![feature(c_variadic)]
#![feature(associated_type_defaults)]
#![feature(extern_types)]
#![feature(fn_ptr_trait)]

mod common;
use common::TestContext;

use vlcrs_macros::module;

use std::ffi::c_int;
use std::marker::PhantomData;
use vlcrs_plugin::{ModuleProtocol,vlc_activate};

unsafe extern "C"
fn activate_filter(_obj: *mut vlcrs_plugin::vlc_object_t) -> c_int
{
    0
}


//
// Create an implementation loader for the TestFilterCapability
//
pub struct FilterModuleLoader<T> {
    _phantom: PhantomData<T>
}

///
/// Signal the core that we can load modules with this loader
///
impl<T> ModuleProtocol<T, vlc_activate> for FilterModuleLoader<T>
    where T: TestNoDeactivateCapability
{
    fn activate_function() -> vlc_activate
    {
        activate_filter
    }
}

/* Implement dummy module capability */
pub trait TestNoDeactivateCapability : Sized {
    type Activate = vlc_activate;
    type Deactivate = *mut ();

    type Loader = FilterModuleLoader<Self>;
}

///
/// Create a dummy module using this capability
///
pub struct TestModule;
impl TestNoDeactivateCapability for TestModule {}

//
// Define a module manifest using this module capability
// and this module.
//
module! {
    type: TestModule (TestNoDeactivateCapability),
    capability: "video_filter" @ 0,
    category: VIDEO_VFILTER,
    description: "A new module",
    shortname: "mynewmodule",
    shortcuts: ["mynewmodule_filter"],
}

//
// This test uses the defined capability and module from above
// and tries to load the manifest and open an instance of the
// module.
//
#[test]
fn test_module_load_default_deactivate()
{
    use vlcrs_plugin::ModuleProperties;
    let mut context = TestContext::<vlc_activate> {
        command_cursor: 0,
        commands: vec![
            ModuleProperties::MODULE_CREATE,
            ModuleProperties::MODULE_NAME,
            ModuleProperties::MODULE_CAPABILITY,
            ModuleProperties::MODULE_SCORE,
            ModuleProperties::MODULE_DESCRIPTION,
            ModuleProperties::MODULE_SHORTNAME,
            ModuleProperties::MODULE_SHORTCUT,
            ModuleProperties::MODULE_CB_OPEN,
            ModuleProperties::CONFIG_CREATE,
            ModuleProperties::CONFIG_VALUE,
        ],
        open_cb: None,
        close_cb: None,
    };
    let ret = common::load_manifest(&mut context, vlc_entry);
    assert_eq!(ret, 0);
    assert_ne!(context.open_cb, None);
    assert_eq!(context.close_cb, None);
}
