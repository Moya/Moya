#!/bin/sh
set -e

echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

install_framework()
{
  echo "rsync --exclude '*.h' -av ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
  rsync -av "${BUILT_PRODUCTS_DIR}/Pods-DemoTests/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
}

if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_framework 'Alamofire.framework'
  install_framework 'LlamaKit.framework'
  install_framework 'Moya.framework'
  install_framework 'Nimble.framework'
  install_framework 'Quick.framework'
  install_framework 'ReactiveCocoa.framework'
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_framework 'Alamofire.framework'
  install_framework 'LlamaKit.framework'
  install_framework 'Moya.framework'
  install_framework 'Nimble.framework'
  install_framework 'Quick.framework'
  install_framework 'ReactiveCocoa.framework'
fi
