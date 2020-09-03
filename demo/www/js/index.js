document.addEventListener('deviceready', onDeviceReady, false);	
function onDeviceReady() {   	
    AudioPlayer.initialize().then(() => {
        window.alert('initialized')
    });

    const checkInitBtn = document.querySelector('.checkInitBtn');
    checkInitBtn.addEventListener('click', () => {
        AudioPlayer.checkInit().then(() => {
            window.alert('initialized!!');
        });
    });

}
