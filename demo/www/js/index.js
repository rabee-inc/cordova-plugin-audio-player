document.addEventListener('deviceready', onDeviceReady, false);	
function onDeviceReady() {   	


    const createBtn = document.querySelector('.createBtn');
    createBtn.addEventListener('click', async() => {
        const player1 = await AudioPlayerManager.create({
            id: 'hoge',
            url: 'hoge',
            isLoop: false
        });

        console.log(player1);

    });

}
